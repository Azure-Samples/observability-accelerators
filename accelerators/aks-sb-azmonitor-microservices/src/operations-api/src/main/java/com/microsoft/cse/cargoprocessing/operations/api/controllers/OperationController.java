package com.microsoft.cse.cargoprocessing.operations.api.controllers;

import org.springframework.http.ResponseEntity;

import com.microsoft.cse.cargoprocessing.operations.api.models.Operation;

public interface OperationController {
    ResponseEntity<Operation> getOperation(String operationId);
    ResponseEntity<Operation> putOperation(String operationId);
}
