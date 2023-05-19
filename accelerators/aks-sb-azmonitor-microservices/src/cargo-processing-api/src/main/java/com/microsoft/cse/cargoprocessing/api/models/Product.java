package com.microsoft.cse.cargoprocessing.api.models;

import java.io.Serializable;

import lombok.Data;

@Data
public class Product implements Serializable {
  private String name;
  private int quantity;
}
