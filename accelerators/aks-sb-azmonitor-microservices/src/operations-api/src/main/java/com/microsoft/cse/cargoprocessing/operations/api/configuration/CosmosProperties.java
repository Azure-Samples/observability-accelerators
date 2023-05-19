package com.microsoft.cse.cargoprocessing.operations.api.configuration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;

import lombok.Data;

@ConfigurationProperties
@Data
public class CosmosProperties {
    @Value("${COSMOS_DB_ENDPOINT:defaultValue}")
    private String uri;

    @Value("${COSMOS_DB_KEY:defaultValue}")
    private String key;

    @Value("${COSMOS_DB_DATABASE_NAME:defaultValue}")
    private String dbName;
}
