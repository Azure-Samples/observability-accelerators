package com.microsoft.cse.cargoprocessing.api.services;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;

import org.apache.commons.io.IOUtils;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.microsoft.cse.cargoprocessing.api.Exceptions.JsonValidationException;

@SpringBootTest
public class SchemaValidatorTest {
  @Autowired
  private SchemaValidator validator;

  @Test
  void UsingValidJsonAndSchema() throws IOException {
    String cargo = IOUtils.toString(
      this.getClass().getResourceAsStream("/cargo-test-objects/basic-cargo.json"),
      "UTF-8");
    ObjectMapper mapper = new ObjectMapper();
    JsonNode jsonCargo = mapper.readTree(cargo);
    assertDoesNotThrow(() -> validator.validate("cargo", jsonCargo));
    
  }

  @Test
  void UsingInvalidSchema() throws IOException {
    String cargo = IOUtils.toString(
      this.getClass().getResourceAsStream("/cargo-test-objects/invalid-cargo-object.json"),
      "UTF-8");
    ObjectMapper mapper = new ObjectMapper();
    JsonNode jsonCargo = mapper.readTree(cargo);
    
    assertThrows(JsonValidationException.class, () -> validator.validate("cargo", jsonCargo));
    
  }
}
