import { ServiceBusSender } from '@azure/service-bus';
import { ServiceBusReceiverWithTelemetry } from '../services/ServiceBusWithTelemetry';
import { ChaosMonkey } from "./ChaosMonkey";

export class ServiceBusKillingMonkey extends ChaosMonkey {
    constructor(queueReceiver: ServiceBusReceiverWithTelemetry) {
        super("service-bus-failure", queueReceiver);
    }

    async wakeTheMonkey(parameters: Map<string, object>): Promise<void> {
        const sender = parameters.get("sender") as ServiceBusSender;
        await sender.close();
    }
}