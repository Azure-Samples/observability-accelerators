namespace ValidCargoProcessor.Services
{
    using System.Net.Sockets;
    using System.Threading;
    using System.Text.Json;
    using Microsoft.Extensions.Diagnostics.HealthChecks;

    public class HealthCheckController : IHostedService
    {
        private readonly HealthCheckService _healthCheckService;
        private readonly ILogger<HealthCheckController> _logger;
        private readonly TcpListener _tcpServer;

        public HealthCheckController(
            TcpListener tcpServer,
            HealthCheckService healthCheckService,
            IConfiguration configuration,
            ILogger<HealthCheckController> logger)
        {
            _healthCheckService = healthCheckService;
            _logger = logger;
            _tcpServer = tcpServer;
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("Starting Tcp Health Check Listener at {}", _tcpServer.LocalEndpoint);
                _tcpServer.Start();
                while (!cancellationToken.IsCancellationRequested)
                {
                    _logger.LogInformation("Performing health check");
                    HealthReport report = await _healthCheckService.CheckHealthAsync().ConfigureAwait(false);

                    if (report == null || report.Status == HealthStatus.Unhealthy)
                    {
                        // default log level for service is set to Debug in appsettings.json
                        _logger.LogDebug("Service is unhealthy, stopping health service", report);
                        _tcpServer.Stop();
                        return;
                    }

                    await ReportHealthCheckResult(report);
                }
            }
            catch (SocketException e)
            {
                _logger.LogError("Tcp Socket Exception", e);
            }
            finally
            {
                _tcpServer.Stop();
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogDebug("Stopping Tcp Listener");
            return Task.FromResult(_tcpServer.Stop);
        }

        private async Task ReportHealthCheckResult(HealthReport report)
        {
            TcpClient client = await _tcpServer.AcceptTcpClientAsync().ConfigureAwait(false);
            try
            {
                NetworkStream stream = client.GetStream();
                String output = JsonSerializer.Serialize(report);
                Byte[] results = System.Text.Encoding.UTF8.GetBytes(output);
                await stream.WriteAsync(results);
                client.Close();
            }
            catch (Exception ex)
            {
                _logger.LogError("Exception occurred while attempting to provide health report", ex);
                client.Close();
            }
        }
    }
}