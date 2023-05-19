namespace ValidCargoProcessor
{
    using System.Threading.Tasks;
    using Azure.Messaging.ServiceBus;
    using Newtonsoft.Json;
    using System.Net;
    using Microsoft.Azure.Cosmos;
    using Microsoft.ApplicationInsights.DataContracts;
    using Microsoft.ApplicationInsights;
    using Microsoft.ApplicationInsights.Extensibility;
    using System.Diagnostics;
    using Microsoft.ApplicationInsights.Metrics;

    public class SubscriptionReceiver : ISubscriptionReceiver
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<SubscriptionReceiver> _logger;
        private readonly ServiceBusClient _serviceBusClient;
        private readonly ServiceBusProcessor _processor;
        private readonly ServiceBusSender _sender;
        private readonly CosmosClient _cosmosClient;
        private readonly TelemetryClient _telemetryClient;
        private readonly MetricConfiguration _customMetricConfiguration;

        private readonly Container _container;
        public SubscriptionReceiver(IConfiguration configuration,
            ILogger<SubscriptionReceiver> logger,
            CosmosClient cosmosClient, ServiceBusClient serviceBusClient, TelemetryClient telemetryClient)
        {
            _configuration = configuration;
            _logger = logger;
            _cosmosClient = cosmosClient;
            _serviceBusClient = serviceBusClient;
            _container = _cosmosClient.GetDatabase(_configuration["CosmosDB:Database"]).GetContainer(_configuration["CosmosDB:Container"]);
            var prefetchCount = _configuration["ServiceBus:PrefetchCount"] == string.Empty ? 10 : int.Parse(_configuration["ServiceBus:PrefetchCount"]);
            var maxConcurrentCalls = _configuration["ServiceBus:MaxConcurrentCalls"] == string.Empty ? 10 : int.Parse(_configuration["ServiceBus:MaxConcurrentCalls"]);
            _processor = _serviceBusClient.CreateProcessor(_configuration["ServiceBus:Topic"], _configuration["ServiceBus:Subscription"], new ServiceBusProcessorOptions
            {
                PrefetchCount = prefetchCount,
                MaxConcurrentCalls = maxConcurrentCalls
            });
            _sender = _serviceBusClient.CreateSender(_configuration["ServiceBus:Queue"]);
            _telemetryClient = telemetryClient;
            _customMetricConfiguration = new MetricConfiguration(seriesCountLimit: 100, valuesPerDimensionLimit: 40, new MetricSeriesConfigurationForMeasurement(restrictToUInt32Values: false));
        }

        private async Task MessageHandler(ProcessMessageEventArgs args)
        {
            ServiceBusReceivedMessage receivedMessage = args.Message;
            string body = receivedMessage.Body.ToString();
            _logger.LogInformation($"Received: {body} from subscription");

            if (receivedMessage.ApplicationProperties.TryGetValue("Diagnostic-Id", out var objectId) && objectId is string diagnosticId)
            {
                string traceId = diagnosticId.Split('-')[1];
                string parentId = diagnosticId.Split('-')[2];
                using (var operation = _telemetryClient.StartOperation<RequestTelemetry>("ServiceBusTopic.ProcessMessage", traceId, parentId))
                {
                    operation.Telemetry.Url = new Uri($"sb://{_configuration["ServiceBus:Subscription"]}");
                    await ProcessMessagesAsync(args, body, operation);
                }
            }
            else
            {
                _logger.LogError("Message is missing telemetry tracking information.");
                await args.DeadLetterMessageAsync(args.Message, "Missing telemetry tracking information");
            }
        }

        private async Task ProcessMessagesAsync(ProcessMessageEventArgs args, string body, IOperationHolder<RequestTelemetry> operation)
        {
            try
            {
                MessageEnvelope? message = JsonConvert.DeserializeObject<MessageEnvelope>(body);
                if (message != null)
                {
                    ValidCargo cargo = message.Data;
                    await AddItemToContainerAsync(cargo);

                    await SendOperationState(new OperationState
                    {
                        OperationId = message.OperationId,
                        State = "Succeeded",
                        Result = cargo
                    });

                    TrackMultiDimensionalMetrics(cargo);

                    await args.CompleteMessageAsync(args.Message);
                }
                else
                {
                    await args.DeadLetterMessageAsync(args.Message, "Null cargo.");
                    _logger.LogError($"Cargo object is null. Message deadlettered");
                }
            }
            catch (Exception ex)
            {
                _telemetryClient.TrackException(ex);
                operation.Telemetry.Success = false;
                _logger.LogError($"Exception encountered - ${ex.Message}. Message deadlettered.");
                //Making sure our dead letter reason isn't larger than the max length ServiceBus will allow
                await args.DeadLetterMessageAsync(args.Message,
                    ex.Message.Substring(0, Math.Min(4096, ex.Message.Length)));
            }
        }

        private void TrackMultiDimensionalMetrics(ValidCargo cargo)
        {
            var metric = _telemetryClient.GetMetric("port_product_qty", "product", "source", "destination", _customMetricConfiguration);

            metric.TrackValue(cargo.Product.Quantity,
                cargo.Product.Name,
                cargo.Port.Source,
                cargo.Port.Destination);
        }

        private async Task SendOperationState(OperationState operationState)
        {
            _logger.LogInformation($"Sending operation state {operationState.OperationId} message to {_configuration["ServiceBus:Queue"]} queue");
            var message = new ServiceBusMessage(JsonConvert.SerializeObject(operationState));
            await _sender.SendMessageAsync(message);
        }

        private Task ErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError(args.Exception.ToString());
            return Task.CompletedTask;
        }

        public async Task ProcessMessagesAsync()
        {
            _processor.ProcessMessageAsync += MessageHandler;
            _processor.ProcessErrorAsync += ErrorHandler;
            await _processor.StartProcessingAsync();
        }

        public async Task StopProcessingAsync()
        {
            await _processor.StopProcessingAsync();
            await _processor.DisposeAsync();
            await _serviceBusClient.DisposeAsync();
        }

        public async Task AddItemToContainerAsync(ValidCargo cargo)
        {
            try
            {
                ItemResponse<ValidCargo> cargoResponse = await _container.ReadItemAsync<ValidCargo>(cargo.Id, new PartitionKey(cargo.Id));
                _logger.LogInformation($"Item in database with id: {cargoResponse.Resource.Id} already exists.");
            }
            catch (CosmosException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
            {
                ItemResponse<ValidCargo> cargoResponse = await _container.CreateItemAsync<ValidCargo>(cargo, new PartitionKey(cargo.Id));
                _logger.LogInformation($"Created item in database with id: {cargoResponse.Resource.Id} Operation consumed {cargoResponse.RequestCharge} RUs.");
            }
        }
    }
}