package com.microsoft.cse.cargoprocessing.api.controllers.ExceptionHandling;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import com.microsoft.cse.cargoprocessing.api.Exceptions.JsonValidationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ControllerAdvice
public class ExceptionAdvisor extends ResponseEntityExceptionHandler {

  private static final Logger logger = LoggerFactory.getLogger(ExceptionAdvisor.class);

  @ExceptionHandler(JsonValidationException.class)
  protected ResponseEntity<Object> handleJsonValidationException(
    JsonValidationException ex, 
    WebRequest request) {
      logger.error(ex.getMessage(), ex);
      
      InnerError innerError = ex.getFailureCode() == 
      ErrorCodes.FAILS_SCHEMA_VALIDATION 
        ? new ValidationError(ex.getFailureCode(), ex.getMessage(), ex.getValidationMessages()) 
        : new InnerError(ex.getFailureCode(), ex.getMessage());
      Error error = new Error(
        ErrorCodes.INVALID_JSON, 
        "Invalid Json object, please see inner error for details", 
        request.getDescription(false), innerError);
      
      return new ResponseEntity<>(error, new HttpHeaders(), HttpStatus.BAD_REQUEST);
  }

  @ExceptionHandler(Exception.class)
  protected ResponseEntity<Object> handleDefaultExceptions(
    Exception ex, 
    WebRequest request) {
      logger.error(ex.getMessage(), ex);

      Error error = new Error(ErrorCodes.INTERNAL_SERVER_ERROR, 
        "Internal server error. Please see service logs for more information", 
        request.getDescription(false), null);

      return new ResponseEntity<>(error, new HttpHeaders(), HttpStatus.INTERNAL_SERVER_ERROR);
  }
  
}
