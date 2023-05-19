package com.microsoft.cse.cargoprocessing.operations.api.ExceptionHandling;

import java.io.Serializable;

import lombok.Data;

@Data
public class ErrorDetail implements Serializable {
  private String code;
  private String message;
  private String target;
  private InnerError innerError;

  public ErrorDetail(String code, String message, String target, InnerError innerError){
    this.code = code;
    this.innerError = innerError;
    this.target = target;
    this.message = message;
  }
}
