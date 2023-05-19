using Microsoft.ApplicationInsights;

namespace ValidCargoProcessor
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly TelemetryClient _telemetryClient;
        private readonly ISubscriptionReceiver _subscriptionReceiver;

        public Worker(ILogger<Worker> logger, TelemetryClient tc, ISubscriptionReceiver subscriptionReceiver)
        {
            _logger = logger;
            _telemetryClient = tc;
            _subscriptionReceiver = subscriptionReceiver;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Starting processing");
            await _subscriptionReceiver.ProcessMessagesAsync();
        }

        public override async Task StopAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Stopping processing");
            await _subscriptionReceiver.StopProcessingAsync();
        }
    }
}
