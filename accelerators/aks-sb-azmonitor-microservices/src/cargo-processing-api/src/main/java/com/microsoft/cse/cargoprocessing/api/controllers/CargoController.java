package com.microsoft.cse.cargoprocessing.api.controllers;

import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.microsoft.cse.cargoprocessing.api.Exceptions.JsonValidationException;
import com.microsoft.cse.cargoprocessing.api.chaos.impl.DependantApiFailureMonkey;
import com.microsoft.cse.cargoprocessing.api.chaos.impl.ProcessKillingMonkey;
import com.microsoft.cse.cargoprocessing.api.models.Cargo;
import com.microsoft.cse.cargoprocessing.api.models.MessageEnvelope;
import com.microsoft.cse.cargoprocessing.api.services.CargoPublisher;
import com.microsoft.cse.cargoprocessing.api.services.OperationPublisher;
import com.microsoft.cse.cargoprocessing.api.services.SchemaValidator;

import lombok.SneakyThrows;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Timestamp;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
@RequestMapping("cargo")
public class CargoController {
  @Autowired
  private CargoPublisher publisher;
  @Autowired
  private SchemaValidator validator;
  @Autowired
  private OperationPublisher operationPublisher;
  @Autowired
  private DependantApiFailureMonkey apiFailingMonkey;
  @Autowired
  private ProcessKillingMonkey processKillingMonkey;

  private static final Logger logger = LoggerFactory.getLogger(CargoController.class);

  private static final ObjectMapper objectMapper = new ObjectMapper();

  @PutMapping("/{cargoId}")
  public ResponseEntity<Cargo> createCargo(@PathVariable String cargoId, @RequestBody String cargoBody,
      @RequestHeader Map<String, String> headers) {
    Cargo cargo = getJsonCargo(cargoBody);

    // Let's see if we need to add a little chaos
    processKillingMonkey.RattleTheCage(cargo);

    cargo.setId(cargoId);
    logger.info("Cargo body loaded for cargo id: {}", cargoId);

    return processCargo(cargo, getOperationId(headers, cargo));
  }

  private String getOperationId(Map<String, String> headers, Cargo cargo) {
    String key = "operation-id";
    if (headers.containsKey(key)) {
      return headers.get(key);
    }
    // If the client doesn't provide an operation-id, generate a
    // deterministic UUID based on the cargo object provided
    return generateId(cargo);
  }

  @PostMapping("/")
  public ResponseEntity<Cargo> createCargo(@RequestBody String cargoBody, @RequestHeader Map<String, String> headers) {
    Cargo cargo = getJsonCargo(cargoBody);
    
    // Let's see if we need to add a little chaos
    processKillingMonkey.RattleTheCage(cargo);

    cargo.setId(generateId(cargo));
    logger.info("Cargo body loaded for cargo id: {}", cargo.getId());

    // Take note that the cargo object's id has been set at this point,
    // so the UUID that is generated for the operation id
    // (when the client doesn't provide one) will be
    // different then the UUID generated for the cargo object
    return processCargo(cargo, getOperationId(headers, cargo));
  }

  @SneakyThrows
  private String generateId(Cargo cargo) {
    // Get a deterministic UUID based on the cargo object provided
    String cargoString = objectMapper.writeValueAsString(cargo);

    return UUID.nameUUIDFromBytes(cargoString.getBytes()).toString();
  }

  private ResponseEntity<Cargo> processCargo(Cargo cargo, String operationId) {
    // Let's see if we need to add a little chaos
    apiFailingMonkey.RattleTheCage(cargo);

    Boolean isNewOperation = operationPublisher.isNewOperation(operationId).block();

    // To ensure we don't have duplicate requests in play:
    // If the operation was created in the previous call, then we haven't
    // received this request before, so we will process it.
    if (isNewOperation) {
      logger.info("New Cargo request, processing cargo id: {}", cargo.getId());
      cargo.setTimestamp(new Timestamp(System.currentTimeMillis()));
      publisher.publishCargo(new MessageEnvelope(cargo, operationId));

      logger.info("Cargo id {} published", cargo.getId());
    }

    return ResponseEntity.accepted()
        .headers(getHeaders(operationId))
        .body(cargo);
  }

  private HttpHeaders getHeaders(String operationId) {
    HttpHeaders headers = new HttpHeaders();
    headers.add("operation-id", operationId);
    return headers;
  }

  private Cargo getJsonCargo(String cargo) {
    try {
      logger.info("Validating cargo schema");
      JsonNode jsonCargo = objectMapper.readTree(cargo);
      validator.validate("cargo", jsonCargo);

      return objectMapper.treeToValue(jsonCargo, Cargo.class);

    } catch (JsonProcessingException e) {
      throw new JsonValidationException(e);
    }
  }
}
