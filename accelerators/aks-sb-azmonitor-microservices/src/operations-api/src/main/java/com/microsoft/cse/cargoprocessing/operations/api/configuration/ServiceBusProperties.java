package com.microsoft.cse.cargoprocessing.operations.api.configuration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Data;

@Data
@ConfigurationProperties
@Component
public class ServiceBusProperties {
    @Value("${accelerator.queue-name:defaultValue}")
    private String queueName;
    @Value("${servicebus.connection-string:defaultValue}")
    private String connectionString;
    @Value("${servicebus.prefetch-count:defaultValue}")
    private int prefetchCount;
}
