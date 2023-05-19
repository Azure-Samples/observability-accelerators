"""Class used to communicate with the Cosmos Db
"""

import jsons
from logging_config import logger
from azure.cosmos import CosmosClient
from models import InvalidCargo
from app_config import COSMOS_CONTAINER_NAME, COSMOS_DATABASE_NAME, \
    COSMOS_ENDPOINT, COSMOS_KEY

class CargoRepo: #pylint: disable=too-few-public-methods
    """Class used to communicate with the Cosmos Db
    """
    def __init__(self):
        client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
        database = client.get_database_client(database=COSMOS_DATABASE_NAME)
        self.container = database.get_container_client(
            container=COSMOS_CONTAINER_NAME
        )

    def store_cargo(self, invalid_cargo: InvalidCargo):
        """Store the cargo object provided in the cosmos db

        Parameters
        ----------
        invalid_cargo : InvalidCargo
            cargo object to store
        """
        logger.info("Storing invalid cargo in database")
        self.container.upsert_item(body=jsons.dump(invalid_cargo))
    