"""Used to listen for messages from the service bus topic containing
invalid cargo messages
"""
import time
from typing import Awaitable, Callable
from logging_config import logger
import jsons
from azure.servicebus.aio import ServiceBusClient
from models import MessageEnvelope, OperationState
from app_config import SERVICE_BUS_CONNECTION_STR, SERVICE_BUS_MAX_MESSAGE_COUNT, \
    SERVICE_BUS_MAX_WAIT_TIME, SERVICE_BUS_SUBSCRIPTION_NAME, SERVICE_BUS_TOPIC_NAME, \
    HEALTH_CHECK_SERVICE_BUS_DEGRADED_THRESHOLD_SECONDS, \
    HEALTH_CHECK_SERVICE_BUS_UNHEALTHY_THRESHOLD_SECONDS
from telemetry_publisher import TelemetryPublisher
from opencensus.trace.status import Status

#pylint: disable=too-many-instance-attributes

class MessageReceiver:
    """Class used to receive messages from the service bus topic
    """

    def __init__(self, telemetry_publisher: TelemetryPublisher):
        self._telemetry_publisher = telemetry_publisher
        self._configure_service_bus_receiver()
        self._max_message_count = SERVICE_BUS_MAX_MESSAGE_COUNT
        self._max_wait_time = SERVICE_BUS_MAX_WAIT_TIME
        self._last_peeked = 0
        self._degraded_threshold = HEALTH_CHECK_SERVICE_BUS_DEGRADED_THRESHOLD_SECONDS
        self._unhealthy_threshold = HEALTH_CHECK_SERVICE_BUS_UNHEALTHY_THRESHOLD_SECONDS

    def _configure_service_bus_receiver(self):
        logger.info('Creating service bus client')
        servicebus_client = ServiceBusClient.from_connection_string(
            conn_str=SERVICE_BUS_CONNECTION_STR)
        logger.info('Creating receiver')
        self._servicebus_receiver = servicebus_client.get_subscription_receiver(
            topic_name=SERVICE_BUS_TOPIC_NAME,
            subscription_name=SERVICE_BUS_SUBSCRIPTION_NAME
        )

    def _retrieve_value_from_message_application_properties(self, msg, key):
        # Keys and values are byte strings
        byte_key = key.encode()
        byte_value = msg.application_properties[byte_key]
        return byte_value.decode()

    async def listen(
            self, message_processor: Callable,
            state_publisher: Callable[[OperationState, str, str], Awaitable[None]]):
        """Listens for messages from the service bus topic

        Parameters
        ----------
        message_processor : Callable
            Function to call when a message is received
        state_publisher : Callable[[OperationState, str, str], Awaitable[None]]
            Awaitable function to call to update operation state
        """

        logger.info('Retrieving messages')

        if not self.is_healthy():
            # We want to fail hard if the health check returns a false
            raise Exception("Service is not healthy")
        self._last_peeked = time.time()
        received_msgs = await self._servicebus_receiver.receive_messages(
            max_message_count=self._max_message_count,
            max_wait_time=self._max_wait_time)

        for msg in received_msgs:
            logger.info('Processing message')
            # Pull operation and operation parent id from application properties on incoming message
            diagnostic_id = self._retrieve_value_from_message_application_properties(msg, "Diagnostic-Id")
            telemetry_operation_id = diagnostic_id.split("-")[1]
            telemetry_operation_parent_id = diagnostic_id.split("-")[2]
            tracer = self._telemetry_publisher.create_tracer(telemetry_operation_id, telemetry_operation_parent_id)
            # Create request in application insights with parent dependency from cargo-processing-validator
            with self._telemetry_publisher.create_process_message_request_span(tracer, "ServiceBusTopic.ProcessMessage", SERVICE_BUS_SUBSCRIPTION_NAME) as process_message_request:
                try:
                    message = jsons.loads(str(msg), MessageEnvelope)
                    with self._telemetry_publisher.create_cosmos_db_store_dependency_span(tracer, "upsertItem.invalid-cargo") as cosmos_db_store_dependency:
                        message_processor(message.data)
                    with self._telemetry_publisher.create_operations_queue_send_dependency_span(tracer, "operations send") as operations_queue_send_dependency:
                        await state_publisher(OperationState(
                            operationId=message.operationId,
                            state="Succeeded",
                            result=message.data),
                            telemetry_operation_id, operations_queue_send_dependency.span_id)
                    with self._telemetry_publisher.create_validated_cargo_topic_dependency_span(tracer, "validated-cargo complete") as validated_cargo_topic_complete_dependency:
                        await self._servicebus_receiver.complete_message(msg)
                except jsons.DecodeError as err:
                    with self._telemetry_publisher.create_validated_cargo_topic_dependency_span(tracer, "validated-cargo deadletter") as validated_cargo_topic_deadletter_dependency:
                        logger.exception(err)
                        # set request success field to false using open census status code mapping - https://opencensus.io/tracing/span/status/
                        process_message_request.set_status(Status(code=3))
                        await self._servicebus_receiver.dead_letter_message(message=msg, reason=str(err))
                        # Can't update operation state if we can't be sure the message structure actually has an operationId

    def is_healthy(self) -> bool:
        """Performs tests to determine if the message receiver is healthy

        Returns
        -------
        bool
            indicates if the MessageReceiver is healthy
        """
        if self._last_peeked == 0:
            logger.info("First pass of the messaging loop. So far so good.")
            return True

        time_since_last_peek = time.time() - self._last_peeked
        seconds_since_last_peek = str(round(time_since_last_peek, 2))

        if time_since_last_peek > self._unhealthy_threshold:
            logger.critical(
                "Service bus hasn't peeked at messages for over %s seconds",
                seconds_since_last_peek)
            return False

        if time_since_last_peek > self._degraded_threshold:
            logger.warning(
                "Performance degraded: Service bus hasn't peeked at messages for over %s seconds",
                seconds_since_last_peek)
            return True

        logger.info(
            "Message receiver is healthy. %s seconds since last peek.", seconds_since_last_peek)
        return True
