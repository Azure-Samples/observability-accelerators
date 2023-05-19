package com.microsoft.cse.cargoprocessing.api.chaos.impl;

import java.util.Map;

import org.springframework.stereotype.Service;

@Service
public class ProcessKillingMonkey extends BaseMonkey {
    public ProcessKillingMonkey() {
        super("process-ending");
    }

    @Override
    public void WakeTheMonkey(Map<String, Object> parameters) {
        // Completely Kill the application
        System.exit(-1);
    }
}
