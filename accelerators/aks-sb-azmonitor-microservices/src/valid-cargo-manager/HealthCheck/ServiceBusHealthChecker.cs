namespace ValidCargoProcessor.HealthCheck
{
    using System.Diagnostics;
    using ValidCargoProcessor.HealthCheck.Models;
    using System.Threading;
    using System.Threading.Tasks;
    using Azure.Messaging.ServiceBus;
    using Microsoft.Extensions.Diagnostics.HealthChecks;
    using System.Reflection;

    public class ServiceBusHealthChecker : IHealthCheck
    {
        private Stopwatch _stopwatch = new();
        private readonly IConfiguration _configuration;
        private readonly ILogger<ServiceBusHealthChecker> _logger;
        private readonly ServiceBusClient _serviceBusClient;
        private readonly int _maxDurationMs;
        private readonly string _description = "ServiceBus:HealthCheck";

        public ServiceBusHealthChecker(IConfiguration configuration,
            ILogger<ServiceBusHealthChecker> logger, ServiceBusClient serviceBusClient)
        {
            _configuration = configuration;
            _logger = logger;
            _serviceBusClient = serviceBusClient;
            _maxDurationMs = int.Parse(configuration["HealthCheck:ServiceBus:MaxDurationMs"]);
        }

        public void Heartbeat()
        {
            _stopwatch.Restart();
        }

        public Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            return Task.Run(() =>
            {
                Dictionary<string, object> data = new();

                try
                {
                    data.Add("ServiceBus:IsClosed", CheckServiceBusConnectionIsClosed());
                    return ToHealthCheckResult(data);
                }
                catch (ServiceBusException sbe)
                {
                    // log and return Unhealthy
                    _logger.LogError($"ServiceBusException:Health:{sbe.Reason}:{sbe.Source}:{sbe.Message}");

                    data.Add("ServiceBusException", sbe.Message);

                    return new HealthCheckResult(HealthStatus.Unhealthy, _description, sbe, data);
                }
                catch (Exception ex)
                {
                    // log and return unhealthy
                    _logger.LogError($"Exception:Health:{ex.Message}");

                    data.Add("Exception", ex.Message);

                    return new HealthCheckResult(HealthStatus.Unhealthy, _description, ex, data);
                }
            });
        }

        private HealthCheckResult ToHealthCheckResult(Dictionary<string, object> data)
        {
            _logger.LogDebug("Converting data to HealthCheckResult");
            HealthStatus status = HealthStatus.Healthy;

            //Make sure we're reporting the least healthy result that was observed
            foreach (object d in data.Values)
            {
                if (d is HealthCheck h && h.Status != HealthStatus.Healthy)
                {
                    status = h.Status;
                }

                if (status == HealthStatus.Unhealthy)
                {
                    break;
                }
            }

            return new HealthCheckResult(status, this._description, data: data);
        }

        private HealthCheck CheckServiceBusConnectionIsClosed()
        {
            _logger.LogDebug("Checking that we can read the cosmos db account information");
            HealthCheckResultBuilder builder = new HealthCheckResultBuilder()
                .ComponentId("ServiceBus")
                .ComponentType("PubSub")
                .Endpoint("ServiceBus:EndpointUri")
                .TargetDurationMs(this._maxDurationMs);

            try
            {
                // Using this approach until the SDK provides an alternative to testing the state of the service bus connection
                // The ServiceBusConnection object is an internally scoped property and class to the ServiceBus SDK, 
                // so will need to use reflection to get access to it.

                // First we're getting the Connection value
                Type sbcType = typeof(ServiceBusClient);
                PropertyInfo? connectionProperty = sbcType.GetProperty("Connection", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                if (connectionProperty == null) throw new NullReferenceException("Unable to get service bus connection property info");
                var connection = connectionProperty.GetValue(_serviceBusClient);
                if (connection == null) throw new NullReferenceException("Unable to get service bus connection property");

                // Next we need to get the value of the IsClosed property of the connection
                PropertyInfo? isClosedProperty = connection.GetType()
                    .GetProperty("IsClosed", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
                if (isClosedProperty == null) throw new NullReferenceException("Unable to get service bus connection IsClosed property info");

                var isClosed = isClosedProperty.GetValue(connection);
                if (isClosed == null) throw new NullReferenceException("Unable to get service bus connection IsClosed property");

                // If the connection is closed, we have an unhealthy connection
                builder.Status((Boolean)isClosed ? HealthStatus.Unhealthy : HealthStatus.Healthy);

                return builder.build();
            }
            catch (Exception e)
            {
                _logger.LogError($"ServiceBusException:Health:{e.Message}");
                builder.Exception(e);
                return builder.build();
            }
        }
    }
}