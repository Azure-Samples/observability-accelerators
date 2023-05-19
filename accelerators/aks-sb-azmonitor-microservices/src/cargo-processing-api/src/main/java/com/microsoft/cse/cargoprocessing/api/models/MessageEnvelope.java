package com.microsoft.cse.cargoprocessing.api.models;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class MessageEnvelope {
    private Cargo data;
    private String operationId;
}
