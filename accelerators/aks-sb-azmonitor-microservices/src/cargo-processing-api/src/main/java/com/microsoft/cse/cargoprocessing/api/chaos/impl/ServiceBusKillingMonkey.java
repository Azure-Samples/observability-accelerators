package com.microsoft.cse.cargoprocessing.api.chaos.impl;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.azure.messaging.servicebus.ServiceBusSenderClient;

@Service
public class ServiceBusKillingMonkey extends BaseMonkey {
    public ServiceBusKillingMonkey() {
        super("service-bus-failure");
    }

    @Override
    public void WakeTheMonkey(Map<String, Object> parameters) {
        // Oh, let's just close that sender before trying to use it, what could possibly
        // go wrong?
        ServiceBusSenderClient sender = getParm(parameters, "sender", null);
        sender.close();
    }
}
