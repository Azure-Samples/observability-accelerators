package com.microsoft.cse.cargoprocessing.api.chaos.impl;

import java.util.Map;

import org.springframework.stereotype.Service;

@Service
public class DependantApiFailureMonkey extends BaseMonkey {
    public DependantApiFailureMonkey() {
        super("operations-api-failure");
    }

    @Override
    public void WakeTheMonkey(Map<String, Object> parameters) {
        throw new ChaosMonkeyException("Dependant Api Failing");
    }
}
