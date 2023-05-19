package com.microsoft.cse.cargoprocessing.operations.api.models;

import java.io.Serializable;

import lombok.Data;

@Data
public class OperationState implements Serializable {
    private String operationId;
    private String state;
    private Cargo result;
    private String error;
}
