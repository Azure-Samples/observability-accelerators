package com.microsoft.cse.cargoprocessing.api.controllers;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.util.UUID;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.io.IOUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;


import com.microsoft.cse.cargoprocessing.api.models.Cargo;
import com.microsoft.cse.cargoprocessing.api.services.CargoPublisher;
import com.microsoft.cse.cargoprocessing.api.services.SchemaValidator;

import reactor.core.publisher.Mono;

import com.microsoft.cse.cargoprocessing.api.services.OperationPublisher;

@SpringBootTest
@TestInstance(Lifecycle.PER_CLASS)
public class CargoControllerTest {
  @MockBean
  private CargoPublisher publisher;

  @MockBean
  private SchemaValidator validator;

  @MockBean
  private OperationPublisher operationPublisher;

  @Autowired
  private CargoController controller;

  @BeforeEach
  void configureMocks() {
    when(operationPublisher.isNewOperation(any())).thenReturn(Mono.just(true));
  }

  @Test
  void PutValidCargoHydratesAdditionContent() throws IOException {
    String cargo = IOUtils.toString(
        this.getClass().getResourceAsStream("/cargo-test-objects/basic-cargo.json"),
        "UTF-8");

    String id = UUID.randomUUID().toString();

    Map<String, String> headers = new HashMap<>();

    Cargo results = controller.createCargo(id, cargo, headers).getBody();

    assertEquals(id, results.getId());
    assertNotNull(results.getTimestamp());
  }

  @Test
  void PostValidCargoHydratesAdditionContent() throws IOException {
    String cargo = IOUtils.toString(
        this.getClass().getResourceAsStream("/cargo-test-objects/basic-cargo.json"),
        "UTF-8");

    Map<String, String> headers = new HashMap<>();

    Cargo results = controller.createCargo(cargo, headers).getBody();

    assertFalse(results.getId().isBlank());
    assertNotNull(results.getTimestamp());
  }
}
