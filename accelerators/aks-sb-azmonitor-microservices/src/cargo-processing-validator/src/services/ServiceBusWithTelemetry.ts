import { ServiceBusSender, ServiceBusMessage, OperationOptionsBase, DeadLetterOptions, GetMessageIteratorOptions, MessageHandlers, PeekMessagesOptions, ReceiveMessagesOptions, ServiceBusReceivedMessage, ServiceBusReceiver, SubscribeOptions } from '@azure/service-bus';
import { TelemetryService } from './TelemetryService';
import * as appInsights from 'applicationinsights';

export const CUSTOM_PROPERTY_REQUEST_PARENT_ID= 'parent-request-id';

function generateServiceBusDependency(
	telemetryClient: appInsights.TelemetryClient,
	dependencyId: string,
	duration: number,
	serviceBusEntity: string,
	serviceBusAction: string,
	success: boolean
): void {
	telemetryClient.trackDependency({
		target: serviceBusEntity,
		name: `${serviceBusEntity} ${serviceBusAction}`,
		data: '',
		duration: duration,
		resultCode: 200,
		success: success,
		dependencyTypeName: `Azure Service Bus`,
		id: dependencyId,
		properties: {
			"message_bus.destination": serviceBusEntity,
			"ai.operation.name": serviceBusAction,
		},
	});
}
function retrieveParentContextOrGenerateNew(message: ServiceBusReceivedMessage): { operationId: string, operationParentId: string } {
	return retrieveParentContext(message) ?? TelemetryService.generateNewContext();
}
function retrieveParentContext(message: ServiceBusReceivedMessage): { operationId: string, operationParentId: string } | null {
	// pull trace parent set automatically in cargo-processing-api
	const traceParent: any = message.applicationProperties?.traceparent;
	if (!traceParent) {
		return null
	}
	// syntax is <version>-<root_id>-<span_id>-<flags>
	const parts = traceParent.split('-');
	return {
		operationId: parts[1],
		operationParentId: parts[2],
	};
}

export class ServiceBusSenderWithTelemetry {
	// Wraps a ServiceBusSender and adds telemetry
	// Note that this is a simple example and doesn't support all the features of ServiceBusSender:
	//   - it only supports the sendMessages function
	//   - it only supports ServiceBusMessage types (not AmqpAnnotatedMessage etc)

	private sender: ServiceBusSender;
	private telemetryClient: appInsights.TelemetryClient;
	constructor(
		sender: ServiceBusSender,
		telemetryClient: appInsights.TelemetryClient,
	) {
		this.sender = sender;
		this.telemetryClient = telemetryClient;
	}

	public get entityPath(): string {
		return this.sender.entityPath;
	}
	public get isClosed(): boolean {
		return this.sender.isClosed;
	}
	async sendMessages(messages: ServiceBusMessage | ServiceBusMessage[], options?: OperationOptionsBase | undefined): Promise<void> {
		const correlationContext = appInsights.getCorrelationContext();
		const dependencyId: string = TelemetryService.generateOpenTelemetryDependencyId();
		const dependencyStart: bigint = process.hrtime.bigint();

		if (!Array.isArray(messages)) {
			messages = [messages];
		}
		const messagesWithTelemetry: ServiceBusMessage[] = messages.map((message: ServiceBusMessage) => {
			const messageForTopic: ServiceBusMessage = {
				...message,
				applicationProperties: {
					...message.applicationProperties,
					'Diagnostic-Id': `00-${correlationContext.operation.id}-${dependencyId}-01`
				}
			};
			return messageForTopic;
		});

		await this.sender.sendMessages(messagesWithTelemetry, options);

		const dependencyEnd: bigint = process.hrtime.bigint();

		// track dependencies in application insights, ensure they are properly parented
		generateServiceBusDependency(
			this.telemetryClient,
			dependencyId,
			TelemetryService.returnElapsedMillisecondsSinceStart(
				dependencyStart,
				dependencyEnd
			),
			this.entityPath,
			'SendMessage',
			true
		);
	}
	async close(): Promise<void> {
		await this.sender.close();
	}
}

export class ServiceBusReceiverWithTelemetry implements ServiceBusReceiver {
	// Wraps a ServiceBusReceiver and adds telemetry
	// Note that this is a simple example and doesn't support all the features of ServiceBusReceiver:

	private receiver: ServiceBusReceiver;
	private telemetryClient: appInsights.TelemetryClient;
	constructor(
		receiver: ServiceBusReceiver,
		telemetryClient: appInsights.TelemetryClient,
	) {
		this.receiver = receiver;
		this.telemetryClient = telemetryClient;
	}

	public get entityPath(): string {
		return this.receiver.entityPath;
	}
	public get receiveMode(): 'peekLock' | 'receiveAndDelete' {
		return this.receiver.receiveMode;
	}
	public get isClosed(): boolean {
		return this.receiver.isClosed;
	}
	private wrapHandler(handler: MessageHandlers): MessageHandlers {
		// wrap the user's handler so that we can add telemetry for message processing
		return {
			processMessage: async (message: ServiceBusReceivedMessage) => {
				// track time so telemetry operation duration can be calculated
				const requestStart: bigint = process.hrtime.bigint();

				// pull trace and span ids from traceparent so that telemetry can be correlated back 
				// to the original API request
				const { operationId, operationParentId } = retrieveParentContextOrGenerateNew(message);
				const requestId: string = TelemetryService.generateOpenTelemetryRequestId();

				// wrap the processing in a correlation context so that any telemetry is associated with it
				// and can be updated in the telemetry processor
				const spanContext = {
					traceId: operationId,
					spanId: operationParentId,
					traceFlags: 1
				}
				const correlationContext = appInsights.startOperation(spanContext, "ServiceBus.ProcessMessage") ?? undefined;
				correlationContext?.customProperties.setProperty(CUSTOM_PROPERTY_REQUEST_PARENT_ID, requestId)
				await appInsights.wrapWithCorrelationContext(async () => {
					let success = false;
					try {
						// invoke handler's processMessage function
						await handler.processMessage(message);
						success = true;
					} catch (error: any) {
						// track exception
						this.telemetryClient.trackException({
							exception: error,
							properties: {
								"message_bus.destination": this.receiver.entityPath,
								"message_bus.delivery_count": (message.deliveryCount ?? -1).toString(),
							},
							tagOverrides: {
								"ai.operation.id": operationId,
								"ai.operation.parentId": operationParentId,
							}
						})

						// track failure request in application insights, ensure parent is set to dependency from inbound message
						const requestEnd: bigint = process.hrtime.bigint();
						this.telemetryClient.trackRequest({
							name: 'ServiceBus.ProcessMessage',
							url: `sb://${this.receiver.entityPath}`,
							duration: TelemetryService.returnElapsedMillisecondsSinceStart(
								requestStart,
								requestEnd
							),
							resultCode: 500,
							// unsuccessful requests cause exceptions and self destruction, in which case the request isn't logged at all
							// no need to handle sending unsuccessful requests
							success: false,
							id: requestId,
							properties: {
								"message_bus.destination": this.receiver.entityPath,
								"message_bus.delivery_count": (message.deliveryCount ?? -1).toString(),
							},
							tagOverrides: {
								"ai.operation.id": operationId,
								"ai.operation.parentId": operationParentId,
							}
						});

						// rethrow so that Service Bus subscribe sees the exception and calls processError
						throw error;
					}

					// track successful request in application insights, ensure parent is set to dependency from inbound message
					const requestEnd: bigint = process.hrtime.bigint();
					this.telemetryClient.trackRequest({
						name: 'ServiceBus.ProcessMessage',
						url: `sb://${this.receiver.entityPath}`,
						duration: TelemetryService.returnElapsedMillisecondsSinceStart(
							requestStart,
							requestEnd
						),
						resultCode: 200,
						// unsuccessful requests cause exceptions and self destruction, in which case the request isn't logged at all
						// no need to handle sending unsuccessful requests
						success: true,
						id: requestId,
						properties: {
							"message_bus.destination": this.receiver.entityPath,
							"message_bus.delivery_count": (message.deliveryCount ?? -1).toString(),
						},
						tagOverrides: {
							"ai.operation.id": operationId,
							"ai.operation.parentId": operationParentId,
						}
					});
				}, correlationContext)();
			},
			processError: handler.processError,
		};
	}
	subscribe(handlers: MessageHandlers, options?: SubscribeOptions | undefined): { close(): Promise<void>; } {
		return this.receiver.subscribe(this.wrapHandler(handlers), options);
	}
	getMessageIterator(options?: GetMessageIteratorOptions | undefined): AsyncIterableIterator<ServiceBusReceivedMessage> {
		throw new Error('Method not implemented.');
	}
	receiveMessages(maxMessageCount: number, options?: ReceiveMessagesOptions | undefined): Promise<ServiceBusReceivedMessage[]> {
		throw new Error('Method not implemented.');
	}
	receiveDeferredMessages(sequenceNumbers: Long | Long[], options?: OperationOptionsBase | undefined): Promise<ServiceBusReceivedMessage[]> {
		throw new Error('Method not implemented.');
	}
	peekMessages(maxMessageCount: number, options?: PeekMessagesOptions | undefined): Promise<ServiceBusReceivedMessage[]> {
		throw new Error('Method not implemented.');
	}
	async close(): Promise<void> {
		await this.receiver.close();
	}
	async completeMessage(message: ServiceBusReceivedMessage): Promise<void> {
		const queueCompleteDependencyId: string = TelemetryService.generateOpenTelemetryDependencyId();

		const queueCompleteDependencyStart: bigint = process.hrtime.bigint();
		await this.receiver.completeMessage(message);
		const queueCompleteDependencyEnd: bigint = process.hrtime.bigint();

		generateServiceBusDependency(
			this.telemetryClient,
			queueCompleteDependencyId,
			TelemetryService.returnElapsedMillisecondsSinceStart(
				queueCompleteDependencyStart,
				queueCompleteDependencyEnd
			),
			this.entityPath,
			'CompleteMessage',
			true
		);
	}
	abandonMessage(message: ServiceBusReceivedMessage, propertiesToModify?: { [key: string]: any; } | undefined): Promise<void> {
		throw new Error('Method not implemented.');
	}
	deferMessage(message: ServiceBusReceivedMessage, propertiesToModify?: { [key: string]: any; } | undefined): Promise<void> {
		throw new Error('Method not implemented.');
	}
	async deadLetterMessage(message: ServiceBusReceivedMessage, options?: (DeadLetterOptions & { [key: string]: any; }) | undefined): Promise<void> {
		// generate id for dependency
		const dependencyId: string = TelemetryService.generateOpenTelemetryDependencyId();

		// deadletter invalid message structures
		const dependencyStart: bigint = process.hrtime.bigint();
		await this.receiver.deadLetterMessage(message, options);
		const dependencyEnd: bigint = process.hrtime.bigint();

		// track dependency in application insights, ensure it is properly parented
		generateServiceBusDependency(
			this.telemetryClient,
			dependencyId,
			TelemetryService.returnElapsedMillisecondsSinceStart(
				dependencyStart,
				dependencyEnd
			),
			this.entityPath,
			'DeadLetterMessage',
			true
		);
	}
	renewMessageLock(message: ServiceBusReceivedMessage): Promise<Date> {
		throw new Error('Method not implemented.');
	}
}


