package com.microsoft.cse.cargoprocessing.operations.api.ExceptionHandling;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ControllerAdvice
public class ExceptionAdvisor extends ResponseEntityExceptionHandler {

  private static final Logger logger = LoggerFactory.getLogger(ExceptionAdvisor.class);

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
