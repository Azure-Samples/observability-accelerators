package com.microsoft.cse.cargoprocessing.api.services;

import com.fasterxml.jackson.databind.JsonNode;

public interface SchemaValidator {
  void validate(String schemaName, JsonNode json);
}
