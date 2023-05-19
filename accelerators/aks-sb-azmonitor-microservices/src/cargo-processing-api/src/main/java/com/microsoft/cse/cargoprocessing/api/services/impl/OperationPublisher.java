package com.microsoft.cse.cargoprocessing.api.services.impl;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import reactor.core.publisher.Mono;

@Service
public class OperationPublisher implements com.microsoft.cse.cargoprocessing.api.services.OperationPublisher {
    private static final Logger logger = LoggerFactory.getLogger(OperationPublisher.class);

    @Value("${operations.api.url:defaultValue}")
    private String operationApiUrl;

    @Override
    public Mono<Boolean> isNewOperation(String operationId) {
        logger.info("Starting operation {} to {}", operationId, operationApiUrl);
        // Return a true when we're debugging the cargo processing only
        if (operationApiUrl.equals("debug"))
            return Mono.just(true);
        return WebClient.create(operationApiUrl)
                .put()
                .uri("/operations/" + operationId)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .retrieve()
                .toBodilessEntity()
                .map(response -> {
                    return response.getStatusCode() == HttpStatus.CREATED;
                });
    }
}
