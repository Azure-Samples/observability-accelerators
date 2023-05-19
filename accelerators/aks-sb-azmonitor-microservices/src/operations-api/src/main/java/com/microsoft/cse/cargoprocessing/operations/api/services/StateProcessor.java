package com.microsoft.cse.cargoprocessing.operations.api.services;

import java.util.Date;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;

import com.azure.cosmos.models.PartitionKey;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusErrorContext;
import com.azure.messaging.servicebus.ServiceBusException;
import com.azure.messaging.servicebus.ServiceBusFailureReason;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;
import com.azure.messaging.servicebus.ServiceBusReceivedMessage;
import com.azure.messaging.servicebus.ServiceBusReceivedMessageContext;
import com.azure.messaging.servicebus.models.ServiceBusReceiveMode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.microsoft.cse.cargoprocessing.operations.api.configuration.ServiceBusProperties;
import com.microsoft.cse.cargoprocessing.operations.api.models.Operation;
import com.microsoft.cse.cargoprocessing.operations.api.models.OperationState;
import com.microsoft.cse.cargoprocessing.operations.api.repositories.OperationRepo;
import io.opentelemetry.api.trace.Span;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import lombok.SneakyThrows;

@Component
@Scope("application")
public class StateProcessor implements Runnable {
    @Autowired
    private OperationRepo repo;
    @Autowired
    ServiceBusProperties serviceBusProperties;

    private final Logger logger = LoggerFactory.getLogger(StateProcessor.class);

    private ObjectMapper mapper = new ObjectMapper();

    @Override
    public void run() {
        try {
            CountDownLatch countdownLatch = new CountDownLatch(1);

            ServiceBusProcessorClient processor = new ServiceBusClientBuilder()
                    .connectionString(serviceBusProperties.getConnectionString())
                    .processor()
                    .queueName(serviceBusProperties.getQueueName())
                    .disableAutoComplete()
                    .prefetchCount(serviceBusProperties.getPrefetchCount())
                    .receiveMode(ServiceBusReceiveMode.PEEK_LOCK)
                    .processMessage(context -> processMessage(context))
                    .processError(context -> processError(context, countdownLatch))
                    .buildProcessorClient();

            processor.start();
            logger.info("Stopped processing operation state messages");
        } catch (Exception e) {
            logger.error("Error while reading from the operation state service bus", e);
        }
    }

    @SneakyThrows
    private void processMessage(ServiceBusReceivedMessageContext context) {
        ServiceBusReceivedMessage message = context.getMessage();
        OperationState state = mapper.readValue(message.getBody().toBytes(), OperationState.class);
        Optional<Operation> result = repo.findById(state.getOperationId(),
                new PartitionKey(state.getOperationId()));

        Operation operation = null;

        if (result.isPresent()) {
            operation = result.get();
        } else {
            operation = new Operation(state.getOperationId());
        }

        if (validStateTransition(operation.getState(), state.getState())) {
            Date messageEnqueue = Date.from(context.getMessage().getEnqueuedTime().toInstant());
            logger.info("Updating state for operation id: {} from {} to {}", state.getOperationId(),
                    operation.getState(), state.getState());
            operation.setState(state.getState());
            operation.setResult(state.getResult());
            operation.setUpdatedAt(messageEnqueue);
            operation.setError(state.getError());

            Span span = Span.current();
            span.setAttribute("operation-state", operation.getState());

            repo.save(operation);
            context.complete();
        } else {
            logger.info(
                    "State transition for Operation Id {} from {} to {} is invalid, putting message back enqueue for processing.",
                    state.getOperationId(), operation.getState(), state.getState());

            context.abandon();
        }
    }

    private boolean validStateTransition(String from, String to) {
        logger.info("Validating state transition from {} to {}", from, to);

        if (from.equals("New") && to.equals("CargoValidated")) {
            return true;
        }
        if (from.equals("CargoValidated") && to.equals("Succeeded")) {
            return true;
        }
        if (to.equals("Failed")) {
            return true;
        }

        return false;
    }

    private void processError(ServiceBusErrorContext context, CountDownLatch countdownLatch) {
        logger.error("Error when receiving messages from namespace: '%s'. Entity: '%s'%n",
                context.getFullyQualifiedNamespace(), context.getEntityPath());

        if (!(context.getException() instanceof ServiceBusException)) {
            logger.error("Non-ServiceBusException occurred: %s%n", context.getException());
            return;
        }

        ServiceBusException exception = (ServiceBusException) context.getException();
        ServiceBusFailureReason reason = exception.getReason();

        if (reason == ServiceBusFailureReason.MESSAGING_ENTITY_DISABLED
                || reason == ServiceBusFailureReason.MESSAGING_ENTITY_NOT_FOUND
                || reason == ServiceBusFailureReason.UNAUTHORIZED) {
            logger.error("An unrecoverable error occurred. Stopping processing with reason %s: %s%n",
                    reason, exception.getMessage());

            countdownLatch.countDown();
        } else if (reason == ServiceBusFailureReason.MESSAGE_LOCK_LOST) {
            logger.error("Message lock lost for message: %s%n", context.getException());
        } else if (reason == ServiceBusFailureReason.SERVICE_BUSY) {
            try {
                // Choosing an arbitrary amount of time to wait until trying again.
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                logger.error("Unable to sleep for period of time");
            }
        } else {
            logger.error("Error source %s, reason %s, message: %s%n", context.getErrorSource(),
                    reason, context.getException());
        }
    }
}
