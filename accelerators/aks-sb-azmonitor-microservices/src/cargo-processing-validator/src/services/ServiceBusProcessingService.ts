import { Cargo } from '../models/Cargo';
import { MessageEnvelope } from '../models/MessageEnvelope';
import { ProcessEndingMonkey } from '../chaos/ProcessEndingMonkey';
import { ServiceBusKillingMonkey } from '../chaos/ServiceBusKillingMonkey';
import {
  OperationOptionsBase,
  ProcessErrorArgs,
  ServiceBusClient,
  ServiceBusMessage,
  ServiceBusReceivedMessage,
} from '@azure/service-bus';
import { CargoValidationService } from './CargoValidationService';
import { CargoSchemaValidation } from './CargoSchemaValidation';

import { ServiceBusSenderWithTelemetry, ServiceBusReceiverWithTelemetry } from './ServiceBusWithTelemetry';
import * as appInsights from 'applicationinsights';

export const CUSTOM_PROPERTY_CARGO_ID = 'cargo-id';
export const CUSTOM_PROPERTY_CARGO_OPERATION_ID = 'cargo-operation-id';
export const CUSTOM_PROPERTY_CARGO_VALID = 'cargo-valid';
export const CUSTOM_PROPERTY_CARGO_DESTINATION = 'cargo-destination';

export class ServiceBusProcessingService {
  private connectionString: string;
  private queueName: string;
  private topicName: string;
  private operationQueueName: string;
  private maxMessageDequeueCount: number;
  private serviceBusClient: ServiceBusClient;
  private cargoValidationService: CargoValidationService;
  private telemetryClient: appInsights.TelemetryClient;
  private cargoSchemaValidator: CargoSchemaValidation;

  private queueReceiver: ServiceBusReceiverWithTelemetry;
  private operationStateSender: ServiceBusSenderWithTelemetry;
  private topicSender: ServiceBusSenderWithTelemetry;
  private processKillingMonkey: ProcessEndingMonkey;
  private serviceBusKillingMonkey: ServiceBusKillingMonkey;

  constructor(
    connectionString: string,
    queueName: string,
    topicName: string,
    operationQueueName: string,
    maxMessageDequeueCount: number,
    cargoValidationService: CargoValidationService,
    telemetryClient: appInsights.TelemetryClient
  ) {
    this.connectionString = connectionString;
    this.queueName = queueName;
    this.topicName = topicName;
    this.operationQueueName = operationQueueName;
    this.maxMessageDequeueCount = maxMessageDequeueCount;
    this.cargoValidationService = cargoValidationService;
    this.telemetryClient = telemetryClient;
    this.serviceBusClient = new ServiceBusClient(this.connectionString);

    this.queueReceiver = new ServiceBusReceiverWithTelemetry(
      this.serviceBusClient.createReceiver(this.queueName),
      this.telemetryClient);
    this.operationStateSender = new ServiceBusSenderWithTelemetry(
      this.serviceBusClient.createSender(this.operationQueueName),
      this.telemetryClient);
    this.topicSender = new ServiceBusSenderWithTelemetry(
      this.serviceBusClient.createSender(this.topicName),
      this.telemetryClient);

    this.cargoSchemaValidator = new CargoSchemaValidation();

    this.processKillingMonkey = new ProcessEndingMonkey(this.queueReceiver);
    this.serviceBusKillingMonkey = new ServiceBusKillingMonkey(this.queueReceiver);
  }

  startProcessingQueueMessages(): { close(): Promise<void> } {
    const response = this.queueReceiver.subscribe({
      processMessage: this.processMessageFromQueue.bind(this),
      processError: async (args: ProcessErrorArgs) => {
        console.log(args); // Write  to console. The receiver already tracks the exception.
        // exit the process and allow scheduler to restart
        process.exit(1);
      }
    }, {
      autoCompleteMessages: false,
      maxConcurrentCalls: this.maxMessageDequeueCount,
    });
    return response;
  }

  private async processMessageFromQueue(message: ServiceBusReceivedMessage) {
    // validate message schema
    const validSchema = this.cargoSchemaValidator.validate(
      message.body
    );

    if (!validSchema.isValid) {
      console.log('Dead lettering message');
      await this.queueReceiver.deadLetterMessage(
        message,
        {
          deadLetterReason: 'Invalid message structure',
          deadLetterErrorDescription: validSchema.message!,
        }
      );
      // Can't update operation state if we can't be sure the message
      // structure actually has an operationId, no try catch needed
    } else {
      await this.processValidCargoMessage(message);
    }
  }

  private async processValidCargoMessage(message: ServiceBusReceivedMessage) {
    const messageEnvelope = message.body as MessageEnvelope;
    const cargo: Cargo = messageEnvelope.data;
    // Let's add a little chaos
    await this.processKillingMonkey.rattleTheCage(message, cargo);
    // Set the operation ID on the context for the telemetry processor to include in telemetry items
    const correlationContext = appInsights.getCorrelationContext();
    if (correlationContext?.customProperties) {
      correlationContext.customProperties.setProperty(CUSTOM_PROPERTY_CARGO_ID, cargo.id);
      correlationContext.customProperties.setProperty(CUSTOM_PROPERTY_CARGO_OPERATION_ID, messageEnvelope.operationId);
    }
    const sendOptions: OperationOptionsBase = {
      tracingOptions: {
        spanOptions: {
          attributes: {
            [CUSTOM_PROPERTY_CARGO_ID]: cargo.id,
            [CUSTOM_PROPERTY_CARGO_OPERATION_ID]: messageEnvelope.operationId
          }
        }
      }
    }
    try {
      // validate cargo object in message
      const validatedCargo = await this.cargoValidationService.validateCargo(cargo);
      const validatedMessage: ServiceBusMessage = {
        body: {
          operationId: messageEnvelope.operationId,
          data: validatedCargo,
        },
      };
      if (correlationContext?.customProperties) {
        correlationContext.customProperties.setProperty(CUSTOM_PROPERTY_CARGO_VALID, validatedCargo.valid.toString());
        const destination = validatedCargo.port.destination.replaceAll(",", ";"); // can't have ',' in props
        correlationContext.customProperties.setProperty(CUSTOM_PROPERTY_CARGO_DESTINATION, destination);
      }
      sendOptions.tracingOptions!.spanOptions!.attributes!["cargo-valid"] = validatedCargo.valid;

      // add valid property to message so it can be properly filtered
      // add telemetry properties so the cargo manager services can tie child operations to dependency below
      validatedMessage.applicationProperties = {
        valid: validatedCargo.valid,
      };

      // send validated cargo with additional properties to service bus topic
      console.log(`Sending message to ${this.topicName} topic (cargo ID: ${cargo.id}, opid:${messageEnvelope.operationId})`);

      // let's add a little chaos
      await this.serviceBusKillingMonkey.rattleTheCage(message, validatedCargo, new Map<string, object>([["sender", this.topicSender]]));

      await this.topicSender.sendMessages(validatedMessage, sendOptions);

      // send message to operations queue
      console.log(`Sending message to ${this.operationQueueName} queue (cargo ID: ${cargo.id})`);
      const operationStateMessage = {
        body: {
          operationId: messageEnvelope.operationId,
          state: 'CargoValidated',
        },
      };
      await this.operationStateSender.sendMessages(operationStateMessage, sendOptions);

      // complete original message
      await this.queueReceiver.completeMessage(message);
    } catch (e: any) {
      // catching the exception to attempt to update the operation state to failed
      const errorMessage = (e as Error).message;

      const operationStateMessage = {
        body: {
          operationId: messageEnvelope.operationId,
          state: 'Failed',
          error: errorMessage,
        },
      };
      await this.operationStateSender.sendMessages(operationStateMessage, sendOptions);

      // make sure we still self destruct for the exception
      throw e;
    }
  }

}
