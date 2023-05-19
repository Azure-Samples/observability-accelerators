package com.microsoft.cse.cargoprocessing.api.models;

import java.io.Serializable;

import lombok.Data;

@Data
public class Port implements Serializable {
  private String source;
  private String destination;
}
