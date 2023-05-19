namespace ValidCargoProcessor.HealthCheck.Models
{
    using System;
    using System.Globalization;
    using System.Text.Json.Serialization;
    using Microsoft.Extensions.Diagnostics.HealthChecks;


    /// <summary>
    /// Class used to define Health Checks that are performed and their results,
    /// in the format supported by .NET's IHealthCheck
    /// </summary>
    public class HealthCheck
    {
        public const string TimeoutMessage = "Request exceeded expected duration";
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public HealthStatus Status { get; set; }
        public string ComponentId { get; set; } = String.Empty;
        public string ComponentType { get; set; } = String.Empty;
        public TimeSpan Duration { get; set; }
        public TimeSpan TargetDuration { get; set; }
        public string Time { get; set; } = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture);
        public string Endpoint { get; set; } = String.Empty;
        public string Message { get; set; } = String.Empty;
    }
}