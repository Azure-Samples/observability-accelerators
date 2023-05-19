package com.microsoft.cse.cargoprocessing.api.chaos.impl;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusMessage;
import com.azure.messaging.servicebus.ServiceBusSenderClient;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class ServiceBusThrollingMonkey extends BaseMonkey {
    public ServiceBusThrollingMonkey() {
        super("service-bus-throttling");
    }

    @Value("${accelerator.queue-name:defaultValue}")
    private String queueName;
    @Value("${servicebus.connection-string:defaultValue}")
    private String connectionString;

    @Override
    public void WakeTheMonkey(Map<String, Object> parameters) {
        ServiceBusSenderClient sender = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .sender()
                .queueName(queueName)
                .buildClient();

        ServiceBusMessage message = getParm(parameters, "message", null);

        // Let's slam the service bus with that message ALOT, what could go wrong with
        // that?
        // TODO: Not able to get this to actually cause the service bus to throttle the
        // requests. Need to revisit before calling this done.
        Flux.just(1)
                .repeat(10000)
                .flatMap(i -> Mono.fromCallable(() -> {
                    sender.sendMessage(message);
                    return i;
                }))
                .subscribeOn(Schedulers.boundedElastic(), true)
                .subscribe();
    }
}
