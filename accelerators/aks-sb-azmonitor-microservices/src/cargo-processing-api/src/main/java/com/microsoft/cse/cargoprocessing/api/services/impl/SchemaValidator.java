package com.microsoft.cse.cargoprocessing.api.services.impl;

import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.microsoft.cse.cargoprocessing.api.Exceptions.JsonValidationException;
import com.networknt.schema.JsonSchema;
import com.networknt.schema.JsonSchemaFactory;
import com.networknt.schema.SpecVersion;
import com.networknt.schema.ValidationMessage;

@Service
public class SchemaValidator implements com.microsoft.cse.cargoprocessing.api.services.SchemaValidator {
  private static final JsonSchemaFactory schemaFactory = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V201909);
  private static final String JSON_SCHEMAS_PATH = "static/json-schemas/";
  private static final Map<String, JsonSchema> schemas = new HashMap<>();

  public void validate(String schemaName, JsonNode json) {
    JsonSchema jsonSchema = getSchema(schemaName);

    Set<ValidationMessage> results = jsonSchema.validate(json);
    if (!results.isEmpty()) {
      throw new JsonValidationException(results);
    }
  }

  private JsonSchema getSchema(String schemaName) {
    if (schemas.containsKey(schemaName)) {
      return schemas.get(schemaName);
    }

    StringBuilder sb = new StringBuilder(JSON_SCHEMAS_PATH);
    sb.append(schemaName);
    sb.append("-schema.json");

    ClassLoader loader = Thread.currentThread().getContextClassLoader();
    InputStream schemaStream = loader.getResourceAsStream(sb.toString());
    JsonSchema schema = schemaFactory.getSchema(schemaStream);

    schemas.put(schemaName, schema);
    return schema;
  }
}
