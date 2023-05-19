namespace ValidCargoProcessor.HealthCheck
{
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Azure.Cosmos;
    using ValidCargoProcessor.HealthCheck.Models;
    using Microsoft.Extensions.Diagnostics.HealthChecks;
    public class CosmosDbHealthChecker : IHealthCheck
    {
        private readonly CosmosClient _cosmosClient;
        private readonly IConfiguration _configuration;
        private readonly string _description = "CosmosDb:HealthCheck";
        private readonly ILogger<CosmosDbHealthChecker> _logger;
        private readonly int _maxDurationMs;
        public CosmosDbHealthChecker(
            CosmosClient cosmosClient, IConfiguration configuration, ILogger<CosmosDbHealthChecker> logger)
        {
            _cosmosClient = cosmosClient;
            _configuration = configuration;
            _logger = logger;
            _maxDurationMs = int.Parse(configuration["HealthCheck:CosmosDb:MaxDurationMs"]);
        }

        public async Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            Dictionary<string, object> data = new();

            try
            {
                data.Add("CosmosDb:Account", await this.CheckClientAccountAsync().ConfigureAwait(false));

                var database = _cosmosClient.GetDatabase(_configuration["CosmosDb:Database"]);
                data.Add("CosmosDb:Database", await CheckDatabaseAsync(database, cancellationToken).ConfigureAwait(false));

                var container = database.GetContainer(_configuration["CosmosDb:Container"]);
                data.Add("CosmosDb:Container", await CheckContainerAsync(container, cancellationToken).ConfigureAwait(false));

                return ToHealthCheckResult(data);
            }
            catch (CosmosException ce)
            {
                // log and return Unhealthy
                _logger.LogError($"CosmosException:Healthz:{ce.StatusCode}:{ce.ActivityId}:{ce.Message}");

                data.Add("CosmosException", ce.Message);

                return new HealthCheckResult(HealthStatus.Unhealthy, _description, ce, data);
            }
            catch (Exception ex)
            {
                // log and return unhealthy
                _logger.LogError($"Exception:Health:{ex.Message}");

                data.Add("Exception", ex.Message);

                return new HealthCheckResult(HealthStatus.Unhealthy, _description, ex, data);
            }
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

        private async Task<HealthCheck> CheckClientAccountAsync()
        {
            _logger.LogDebug("Checking that we can read the cosmos db account information");
            HealthCheckResultBuilder builder = new HealthCheckResultBuilder()
                .ComponentId("CosmosDb")
                .ComponentType("Data Store")
                .Endpoint(this._configuration["CosmosDb:EndpointUri"])
                .TargetDurationMs(this._maxDurationMs);

            try
            {
                var account = await _cosmosClient.ReadAccountAsync().ConfigureAwait(false);

                return builder.build();
            }
            catch (CosmosException ce)
            {
                _logger.LogError($"CosmosException:Health:{ce.StatusCode}:{ce.ActivityId}:{ce.Message}");
                builder.Exception(ce);
                return builder.build();
            }
        }

        private async Task<HealthCheck> CheckDatabaseAsync(Database database, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("Checking that we can read the cosmos db database information");
            HealthCheckResultBuilder builder = new HealthCheckResultBuilder()
                .ComponentId("CosmosDb")
                .ComponentType("Data Store")
                .Endpoint(this._configuration["CosmosDb:Database"])
                .TargetDurationMs(this._maxDurationMs);

            try
            {
                var dbData = await database.ReadAsync(null, cancellationToken).ConfigureAwait(false);

                return builder.build();
            }
            catch (CosmosException ce)
            {
                _logger.LogError($"CosmosException:Health:{ce.StatusCode}:{ce.ActivityId}:{ce.Message}");
                builder.Exception(ce);
                return builder.build();
            }
        }

        private async Task<HealthCheck> CheckContainerAsync(Container container, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("Checking that we can read the cosmos db container information");
            HealthCheckResultBuilder builder = new HealthCheckResultBuilder()
                .ComponentId("CosmosDb")
                .ComponentType("Data Store")
                .Endpoint(this._configuration["CosmosDb:Container"])
                .TargetDurationMs(this._maxDurationMs);

            try
            {
                var containerData = await container.ReadContainerAsync(null, cancellationToken).ConfigureAwait(false);

                return builder.build();
            }
            catch (CosmosException ce)
            {
                _logger.LogError($"CosmosException:Health:{ce.StatusCode}:{ce.ActivityId}:{ce.Message}");
                builder.Exception(ce);
                return builder.build();
            }
        }
    }
}