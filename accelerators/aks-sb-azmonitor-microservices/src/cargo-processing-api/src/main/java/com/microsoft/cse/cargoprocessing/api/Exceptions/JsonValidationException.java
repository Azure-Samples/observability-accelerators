package com.microsoft.cse.cargoprocessing.api.Exceptions;

import java.util.Set;
import java.util.stream.Collectors;

import com.microsoft.cse.cargoprocessing.api.controllers.ExceptionHandling.ErrorCodes;
import com.networknt.schema.ValidationMessage;

import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper=false)
public class JsonValidationException extends RuntimeException {
  private Set<ValidationMessage> validationMessages;
  private String failureCode;

  public JsonValidationException(Throwable cause) {
    super(cause);
    this.failureCode = ErrorCodes.FAILS_SERIALIZATION;
  }

  public JsonValidationException(Set<ValidationMessage> validationMessages) {
    super(String.format("Json failed validation with the following errors:%n%n* %s",
    validationMessages
        .stream()
        .map(v -> String.format("%s: {%s} %s", v.getCode(), v.getPath(), v.getMessage()))
        .collect(Collectors.joining(String.format("%n* ")))));

    this.validationMessages = validationMessages;
    this.failureCode = ErrorCodes.FAILS_SCHEMA_VALIDATION;
  }
}
