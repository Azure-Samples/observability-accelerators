import { ServiceBusReceivedMessage } from '@azure/service-bus';
import { Cargo } from '../models/Cargo';
import { ServiceBusReceiverWithTelemetry } from '../services/ServiceBusWithTelemetry';

export abstract class ChaosMonkey {
    chaosTrigger: string;
    serviceTrigger: string = "cargo-processing-validator";
    private queueReceiver: ServiceBusReceiverWithTelemetry;

    constructor(chaosTrigger: string, queueReceiver: ServiceBusReceiverWithTelemetry) {
        this.chaosTrigger = chaosTrigger;
        this.queueReceiver = queueReceiver;
    }

    canWakeTheMonkey(cargo: Cargo): boolean {
        return cargo.port.source == this.serviceTrigger && cargo.port.destination == this.chaosTrigger;
    }

    async rattleTheCage(message: ServiceBusReceivedMessage, cargo: Cargo, parameters?: Map<string, object>): Promise<void> {
        if (this.canWakeTheMonkey(cargo)) {
            // Need to make sure we complete the message, otherwise the chaos will not end until the 
            // message has been dequeued the maximum amount of times
            await this.queueReceiver.completeMessage(message);
            await this.wakeTheMonkey(parameters);
        }
    }

    abstract wakeTheMonkey(parameters?: Map<string, object>): Promise<void>;
}