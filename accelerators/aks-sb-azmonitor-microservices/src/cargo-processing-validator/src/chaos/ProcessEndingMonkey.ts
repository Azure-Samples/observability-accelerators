import { ServiceBusReceiverWithTelemetry } from "../services/ServiceBusWithTelemetry";
import { ChaosMonkey } from "./ChaosMonkey";

export class ProcessEndingMonkey extends ChaosMonkey {
    constructor(queueReceiver: ServiceBusReceiverWithTelemetry) {
        super("process-ending", queueReceiver);
    }

    wakeTheMonkey(parameters?: Map<string, object>): Promise<void> {
        process.exit();
    }
}