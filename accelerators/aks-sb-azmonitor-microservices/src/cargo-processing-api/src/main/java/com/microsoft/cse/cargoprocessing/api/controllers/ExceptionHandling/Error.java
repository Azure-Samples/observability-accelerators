package com.microsoft.cse.cargoprocessing.api.controllers.ExceptionHandling;

import java.io.Serializable;

import lombok.Data;

@Data
public class Error implements Serializable {
  private ErrorDetail error;

  public Error(String code, String message, String target, InnerError innerError){
    error = new ErrorDetail(code, message, target, innerError);
  }
}
