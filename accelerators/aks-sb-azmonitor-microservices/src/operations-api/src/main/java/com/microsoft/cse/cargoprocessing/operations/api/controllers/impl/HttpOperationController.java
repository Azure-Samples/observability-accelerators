package com.microsoft.cse.cargoprocessing.operations.api.controllers.impl;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.azure.cosmos.models.PartitionKey;
import com.microsoft.cse.cargoprocessing.operations.api.controllers.OperationController;
import com.microsoft.cse.cargoprocessing.operations.api.models.Operation;
import com.microsoft.cse.cargoprocessing.operations.api.repositories.OperationRepo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("operations")
public class HttpOperationController implements OperationController {
    @Autowired
    private OperationRepo repo;

    private final Logger logger = LoggerFactory.getLogger(HttpOperationController.class);

    @Override
    @GetMapping("/{operationId}")
    public ResponseEntity<Operation> getOperation(@PathVariable String operationId) {
        Optional<Operation> operation = repo.findById(operationId, new PartitionKey(operationId));

        if (operation.isPresent()) {
            logger.info("Operation {} was found in database.", operationId);
            return new ResponseEntity<>(operation.get(), HttpStatus.OK);
        }

        logger.info("Operation {} was not found in database.", operationId);
        return new ResponseEntity<>(HttpStatus.NOT_FOUND);
    }

    @Override
    @PutMapping("/{operationId}")
    public ResponseEntity<Operation> putOperation(@PathVariable String operationId) {
        Operation operation = new Operation(operationId);
        Optional<Operation> stored = repo.findById(operation.getId(), new PartitionKey(operation.getId()));

        if (!stored.isPresent()) {
            logger.info("Operation {} was not found in database. Saving now", operation.getId());
            repo.save(operation);
            return new ResponseEntity<>(operation, HttpStatus.CREATED);
        }

        return new ResponseEntity<>(stored.get(), HttpStatus.OK);
    }
}
