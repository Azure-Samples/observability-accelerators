package com.microsoft.cse.cargoprocessing.operations.api.models;

import java.io.Serializable;
import java.sql.Timestamp;

import com.fasterxml.jackson.annotation.JsonFormat;

import lombok.Data;

@Data
public class Cargo implements Serializable {
  private String id;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", timezone = "GMT")
  private Timestamp timestamp;
  private Product product;
  private Port port;
  private DemandDates demandDates;
  private Boolean valid;
  private String errorMessage;
}
