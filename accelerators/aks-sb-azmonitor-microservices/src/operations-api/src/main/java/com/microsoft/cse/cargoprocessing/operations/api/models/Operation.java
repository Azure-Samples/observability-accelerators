package com.microsoft.cse.cargoprocessing.operations.api.models;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Date;

import org.springframework.data.annotation.Id;

import com.azure.spring.data.cosmos.core.mapping.Container;
import com.azure.spring.data.cosmos.core.mapping.PartitionKey;
import com.fasterxml.jackson.annotation.JsonFormat;

@Data
@Container(containerName = "operations", autoCreateContainer = false)
@NoArgsConstructor
public class Operation implements Serializable {
    @PartitionKey
    @Id
    private String id;
    private String state;
    private Cargo result;
    private String error;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", timezone = "GMT")
    private Date updatedAt;

    public Operation(String operationId) {
        id = operationId;
        state = "New";
        updatedAt = new Date();
    }
}
