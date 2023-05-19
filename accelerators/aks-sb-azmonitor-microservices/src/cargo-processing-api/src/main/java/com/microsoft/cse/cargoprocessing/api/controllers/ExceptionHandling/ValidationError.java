package com.microsoft.cse.cargoprocessing.api.controllers.ExceptionHandling;

import java.util.Set;

import com.networknt.schema.ValidationMessage;

import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper=true)
public class ValidationError extends InnerError {
  private Set<ValidationMessage> validationMessages;

  public ValidationError (String code, String message, Set<ValidationMessage> validationMessages) {
    super(code, message);
    this.validationMessages = validationMessages;
  }
}
