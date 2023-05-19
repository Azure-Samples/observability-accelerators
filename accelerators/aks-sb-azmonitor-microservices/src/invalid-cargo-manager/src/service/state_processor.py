"""Used to send messages to the Operation State Queue"""

import jsons
from azure.servicebus.aio import ServiceBusClient
from azure.servicebus import ServiceBusMessage
from app_config import SERVICE_BUS_CONNECTION_STR, SERVICE_BUS_QUEUE_NAME
from logging_config import logger

from models import OperationState


async def send_operation_state(operation_state: OperationState, telemetry_operation_id: str, telemetry_operation_parent_id: str):
    """Send OperationState to the service bus queue defined in the app settings

    Parameters
    ----------
    operation_state : OperationState
        The Operation State to send
    telemetry_operation_id : str
        The operation id for the trace
    telemetry_operation_parent_id : str
        The id of the current operation in the trace
    """
    servicebus_client = ServiceBusClient.from_connection_string(conn_str=SERVICE_BUS_CONNECTION_STR)
    logger.info("Sending operation state message to % s queue" % SERVICE_BUS_QUEUE_NAME)
    async with servicebus_client:
        sender = servicebus_client.get_queue_sender(queue_name=SERVICE_BUS_QUEUE_NAME)
        async with sender:
            await sender.send_messages(ServiceBusMessage(jsons.dumps(operation_state), application_properties={"Diagnostic-Id": "00-{}-{}-01".format(telemetry_operation_id, telemetry_operation_parent_id)}))
