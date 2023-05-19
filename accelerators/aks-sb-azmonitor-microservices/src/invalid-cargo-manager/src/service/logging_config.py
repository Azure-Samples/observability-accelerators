"""Creates the logger for the application
"""

import logging
import sys
from opencensus.ext.azure.log_exporter import AzureLogHandler
from app_config import LOGGING_APP_NAME, LOGGING_CLOUD_LOGGING_LEVEL, \
    LOGGING_CONSOLE_LOGGING_LEVEL

logger = logging.getLogger(LOGGING_APP_NAME)
 # Set the root level for logging, no handler will be able to report anything lower than this value
logger.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

consoleHandler = logging.StreamHandler()
consoleHandler.setLevel(LOGGING_CONSOLE_LOGGING_LEVEL)
consoleHandler.setFormatter(formatter)
consoleHandler.setStream(sys.stdout)

logger.addHandler(consoleHandler)

def callback_add_role_name(envelope):
    """ Callback function for opencensus """
    envelope.tags["ai.cloud.role"] = LOGGING_APP_NAME
    return True

azureHandler = AzureLogHandler()
azureHandler.setLevel(LOGGING_CLOUD_LOGGING_LEVEL)
azureHandler.add_telemetry_processor(callback_add_role_name)

logger.addHandler(azureHandler)
