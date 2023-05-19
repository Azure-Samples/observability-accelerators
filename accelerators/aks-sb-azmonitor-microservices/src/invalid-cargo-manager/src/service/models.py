"""Module containing the models used by the service implementation
"""

#pylint: disable=too-few-public-methods
#pylint: disable=invalid-name
class Product:
    """Defines the structure for products
    """
    name: str
    quantity: int

class Port:
    """Defines the structure for which ports are defined for cargo
    """
    source: str
    destination: str

class DemandDates:
    """Defines the structure for the demand dates of the cargo
    """
    start: str
    end: str

class Cargo:
    """Defines the structure of a cargo object"""
    id: str
    timestamp: str
    product: Product
    port: Port
    demandDates: DemandDates

class InvalidCargo(Cargo):
    """Extends the cargo base class with information about why the cargo is invalid

    Parameters
    ----------
    Cargo : _type_
        Base class being extended
    """
    valid: bool
    errorMessage: str

class OperationState:
    """Defines the state for operational state messages"""
    result: Cargo
    state: str
    operationId: str
    error: str
    def __init__(self, operationId: str, state: str, result: Cargo=None, error: str=""):
        self.operationId = operationId
        self.state = state
        self.result = result
        self.error = error

class MessageEnvelope:
    """Defines the structure of the messages received from
    the service bus topic"""
    operationId: str
    data: InvalidCargo
