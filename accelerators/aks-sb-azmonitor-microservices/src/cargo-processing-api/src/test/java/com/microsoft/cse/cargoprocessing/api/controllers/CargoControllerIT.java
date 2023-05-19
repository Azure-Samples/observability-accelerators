package com.microsoft.cse.cargoprocessing.api.controllers;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import java.util.stream.Stream;

import org.apache.commons.io.IOUtils;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.microsoft.cse.cargoprocessing.api.services.CargoPublisher;


@SpringBootTest
@AutoConfigureMockMvc
public class CargoControllerIT {
  @Autowired
  private MockMvc mockMvc;

  @MockBean
  private CargoPublisher publisher;

  @ParameterizedTest
  @MethodSource("cargoToPublish")
  void publishesCargo(String cargoSource, ResultMatcher matcher) throws JsonProcessingException, Exception{
    String cargo = IOUtils.toString(
      this.getClass().getResourceAsStream(cargoSource),
      "UTF-8");
    
    String id = UUID.randomUUID().toString();

    mockMvc.perform(
      put("/cargo/{id}", id) 
        .contentType("application/json")
        .content(cargo))
      .andExpect(matcher);
  }

  private static Stream<Arguments> cargoToPublish() {
    return Stream.of(
      Arguments.of("/cargo-test-objects/basic-cargo.json", status().isOk()),
      Arguments.of("/cargo-test-objects/invalid-cargo-object.json", status().isBadRequest()),
      Arguments.of("/cargo-test-objects/invalid-syntax.json", status().isBadRequest())
    );
  }
}
