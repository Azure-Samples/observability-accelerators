package com.microsoft.cse.cargoprocessing.operations.api.configuration;

import com.azure.cosmos.CosmosClientBuilder;

import com.azure.spring.data.cosmos.config.AbstractCosmosConfiguration;
import com.azure.spring.data.cosmos.config.CosmosConfig;
import com.azure.spring.data.cosmos.repository.config.EnableCosmosRepositories;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;


@Configuration
@EnableConfigurationProperties(CosmosProperties.class)
@EnableCosmosRepositories(basePackages = "com.microsoft.cse.cargoprocessing.operations.api")
@PropertySource("classpath:application.properties")
public class CosmosConfiguration extends AbstractCosmosConfiguration {
    @Autowired
    private CosmosProperties properties;

    @Bean
    public CosmosClientBuilder getCosmosClientBuilder() {
        return new CosmosClientBuilder()
            .endpoint(properties.getUri())
            .key(properties.getKey());
    }

    @Bean
    public CosmosConfig cosmosConfig() {
        return CosmosConfig.builder()
            .enableQueryMetrics(true)
            .build();
    }

    @Override
    protected String getDatabaseName() {
        return properties.getDbName();
    }
}
