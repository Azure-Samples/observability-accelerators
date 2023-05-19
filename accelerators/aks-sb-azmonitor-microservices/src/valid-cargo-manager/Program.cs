using System.Net;
using System.Net.Sockets;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration.Json;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using ValidCargoProcessor.HealthCheck;
using ValidCargoProcessor.Services;
using ValidCargoProcessor.Telemetry;

namespace ValidCargoProcessor
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((_, builder) =>
                {
                    builder
                        .Sources.OfType<JsonConfigurationSource>()
                        .First(x => x.Path == "appsettings.json")
                        .Optional = true; // config specified via environment variables when deployed
                })
                .ConfigureServices((hostContext, services) =>
                {
                    IConfiguration configuration = hostContext.Configuration;
                    services.AddHostedService<Worker>()
                            .AddSingleton<ISubscriptionReceiver, SubscriptionReceiver>()
                            .AddSingleton(s => CreateCosmosClient(s, configuration))
                            .AddSingleton(s => CreateTcpServer(s, configuration))
                            .AddSingleton<ITelemetryInitializer, TelemetryInitializer>()
                            .AddHostedService<HealthCheckController>()
                            .AddAzureClients(builder => CreateServiceBusClient(builder, configuration));
                    services.AddHealthChecks()
                            .AddCheck<CosmosDbHealthChecker>("CosmosDb", failureStatus: HealthStatus.Unhealthy)
                            .AddCheck<ServiceBusHealthChecker>("ServiceBus", failureStatus: HealthStatus.Unhealthy);
                    services.AddApplicationInsightsTelemetryWorkerService();
                });

        public static CosmosClient CreateCosmosClient(IServiceProvider s, IConfiguration configuration)
        {
            var endpointUri = configuration["CosmosDB:EndpointUri"];
            var authKey = configuration["CosmosDB:PrimaryKey"];

            if (string.IsNullOrEmpty(endpointUri))
            {
                throw new ArgumentException("CosmosDB endpoint URI is missing");
            }

            if (string.IsNullOrEmpty(authKey))
            {
                throw new ArgumentException("CosmosDB authentication key is missing");
            }

            return new CosmosClient(endpointUri, authKey);
        }

        public static void CreateServiceBusClient(AzureClientFactoryBuilder builder, IConfiguration configuration)
        {
            var serviceBusConnectionString = configuration["ServiceBus:ConnectionString"];

            if (string.IsNullOrEmpty(serviceBusConnectionString))
            {
                throw new ArgumentException("Service Bus connection string is missing");
            }

            builder.AddServiceBusClient(serviceBusConnectionString)
                .ConfigureOptions(options =>
                {
                    
                });
        }

        public static TcpListener CreateTcpServer(IServiceProvider s, IConfiguration configuration)
        {
            int port = int.Parse(configuration["HealthCheck:TcpServer:Port"]);
            string hostName = Dns.GetHostName();

            IPAddress localAddress = Dns.GetHostEntry(hostName).AddressList[0];
            return new TcpListener(localAddress, port);
        }
    }
}
