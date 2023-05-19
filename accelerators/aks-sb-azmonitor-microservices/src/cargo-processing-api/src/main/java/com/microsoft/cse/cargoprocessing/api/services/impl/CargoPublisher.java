package com.microsoft.cse.cargoprocessing.api.services.impl;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusSenderClient;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.microsoft.cse.cargoprocessing.api.chaos.impl.ServiceBusKillingMonkey;
import com.microsoft.cse.cargoprocessing.api.chaos.impl.ServiceBusThrollingMonkey;
import com.microsoft.cse.cargoprocessing.api.models.MessageEnvelope;

import lombok.SneakyThrows;

@Service
public class CargoPublisher implements com.microsoft.cse.cargoprocessing.api.services.CargoPublisher {

  @Autowired
  private ServiceBusKillingMonkey killingMonkey;
  @Autowired
  private ServiceBusThrollingMonkey throttlingMonkey;

  @Value("${accelerator.queue-name:defaultValue}")
  private String queueName;
  @Value("${servicebus.connection-string:defaultValue}")
  private String connectionString;

  private JsonMapper mapper = new JsonMapper();

  private static final Logger logger = LoggerFactory.getLogger(CargoPublisher.class);

  @SneakyThrows
  public void publishCargo(MessageEnvelope envelope) {
    ServiceBusSenderClient sender = new ServiceBusClientBuilder()
        .connectionString(connectionString)
        .sender()
        .queueName(queueName)
        .buildClient();

    logger.info("Cargo being published");
    ServiceBusMessage message = new ServiceBusMessage(mapper.writeValueAsBytes(envelope));
    message.addContext(connectionString, message);

    // Maybe add a little chaos
    Map<String, Object> chaosParameters = Map.of("sender", sender, "message", message);
    killingMonkey.RattleTheCage(envelope.getData(), chaosParameters);
    throttlingMonkey.RattleTheCage(envelope.getData(), chaosParameters);

    sender.sendMessage(message);
    sender.close();
  }
}
