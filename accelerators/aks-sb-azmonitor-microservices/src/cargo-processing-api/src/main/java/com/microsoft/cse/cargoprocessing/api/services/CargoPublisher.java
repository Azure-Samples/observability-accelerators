package com.microsoft.cse.cargoprocessing.api.services;

import com.microsoft.cse.cargoprocessing.api.models.MessageEnvelope;

public interface CargoPublisher {
  void publishCargo(MessageEnvelope envelope);
}
