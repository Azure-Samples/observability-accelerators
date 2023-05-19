"""Centralized location for application setting to be loaded
"""
import os

COSMOS_ENDPOINT = os.environ['COSMOS_DB_ENDPOINT']
COSMOS_KEY = os.environ['COSMOS_DB_KEY']
COSMOS_DATABASE_NAME = os.environ['COSMOS_DB_DATABASE_NAME']
COSMOS_CONTAINER_NAME = os.environ['COSMOS_DB_CONTAINER_NAME']

LOGGING_APP_NAME = 'invalid-cargo-manager'
LOGGING_CLOUD_LOGGING_LEVEL = os.environ['CLOUD_LOGGING_LEVEL'].upper()
LOGGING_CONSOLE_LOGGING_LEVEL = os.environ['CONSOLE_LOGGING_LEVEL'].upper()

SERVICE_BUS_CONNECTION_STR = os.environ['SERVICE_BUS_CONNECTION_STR']
SERVICE_BUS_TOPIC_NAME = os.environ["SERVICE_BUS_TOPIC_NAME"]
SERVICE_BUS_QUEUE_NAME = os.environ["SERVICE_BUS_QUEUE_NAME"]
SERVICE_BUS_SUBSCRIPTION_NAME = os.environ["SERVICE_BUS_SUBSCRIPTION_NAME"]
SERVICE_BUS_MAX_MESSAGE_COUNT = int(
    os.environ["SERVICE_BUS_MAX_MESSAGE_COUNT"])
SERVICE_BUS_MAX_WAIT_TIME = int(os.environ["SERVICE_BUS_MAX_WAIT_TIME"])

HEALTH_CHECK_SERVICE_BUS_DEGRADED_THRESHOLD_SECONDS = int(
    os.environ["HEALTH_CHECK_SERVICE_BUS_DEGRADED_THRESHOLD_SECONDS"])
HEALTH_CHECK_SERVICE_BUS_UNHEALTHY_THRESHOLD_SECONDS = int(
    os.environ["HEALTH_CHECK_SERVICE_BUS_UNHEALTHY_THRESHOLD_SECONDS"])
