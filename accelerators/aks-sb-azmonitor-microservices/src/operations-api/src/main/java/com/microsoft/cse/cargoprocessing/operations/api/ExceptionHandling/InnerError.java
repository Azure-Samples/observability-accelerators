package com.microsoft.cse.cargoprocessing.operations.api.ExceptionHandling;

import java.io.Serializable;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class InnerError implements Serializable {
  private String code;
  private String message;
}
