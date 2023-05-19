package com.microsoft.cse.cargoprocessing.api.controllers.ExceptionHandling;

public class ErrorCodes {
  private ErrorCodes() { throw new IllegalStateException("Utility class, should not be constructed"); }

  public static final String INVALID_JSON = "InvalidJson";
  public static final String FAILS_SCHEMA_VALIDATION = "InvalidJson-SchemaValidationFailure";
  public static final String FAILS_SERIALIZATION = "InvalidJson-UnableToSerialize";

  public static final String INTERNAL_SERVER_ERROR  = "InternalServerError";
}
