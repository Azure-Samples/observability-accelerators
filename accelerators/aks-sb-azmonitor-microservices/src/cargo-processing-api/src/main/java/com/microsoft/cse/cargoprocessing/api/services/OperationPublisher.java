package com.microsoft.cse.cargoprocessing.api.services;

import reactor.core.publisher.Mono;

public interface OperationPublisher {
    Mono<Boolean> isNewOperation(String operationId);
}
