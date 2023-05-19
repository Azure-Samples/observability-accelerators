"""Contains the primary objects that make up the applications context
"""
from logging_config import logger
from state_processor import send_operation_state
from message_receiver import MessageReceiver
from cargo_repo import CargoRepo
from healthcheck import EnvironmentDump
from telemetry_publisher import TelemetryPublisher

#pylint: disable=too-few-public-methods


class ApplicationContext:
    """Class defining the context of the application
    """

    def __init__(self):
        self._telemetry_publisher: TelemetryPublisher = TelemetryPublisher()
        self._cargo_repo: CargoRepo = CargoRepo()
        self._message_receiver: MessageReceiver = MessageReceiver(
            telemetry_publisher=self._telemetry_publisher)
        self._environment_dump = EnvironmentDump()

    async def start(self):
        """Entry point for the application
        """
        env_dump = self._environment_dump.run()[0]
        logger.info("Environment Dump: %s", env_dump)
        logger.info("Entering listening loop")
        try:
            while True:
                await self._message_receiver.listen(
                    self._cargo_repo.store_cargo, send_operation_state)
        except BaseException as err:  # pylint: disable=broad-except
            # Want to ensure the exception is logged on our way out
            logger.exception(err)
