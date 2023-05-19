namespace ValidCargoProcessor.HealthCheck.Models
{
    using System;
    using System.Collections.Generic;
    using Microsoft.Extensions.Diagnostics.HealthChecks;

    /// <summary>
    /// Class used to define Health Checks that are performed and their results,
    /// in the format documented by the Internet Engineering Task Force (IETF)
    /// https://datatracker.ietf.org/doc/html/draft-inadarei-api-health-check-06
    /// </summary>
    public class IetfHealthCheck
    {
        public string Status { get; set; } = String.Empty;
        public string ComponentId { get; set; } = String.Empty;
        public string ComponentType { get; set; } = String.Empty;
        public string ObservedUnit { get; set; } = String.Empty;
        public double ObservedValue { get; set; }
        public double TargetValue { get; set; }
        public string Time { get; set; } = String.Empty;
        public List<string> AffectedEndpoints { get; } = new List<string>();
        public string Message { get; set; } = String.Empty;

        public IetfHealthCheck(HealthCheck healthCheck)
        {
            if (healthCheck == null)
            {
                throw new ArgumentNullException(nameof(healthCheck));
            }

            Status = ToIetfStatus(healthCheck.Status);
            ComponentId = healthCheck.ComponentId;
            ComponentType = healthCheck.ComponentType;
            ObservedValue = Math.Round(healthCheck.Duration.TotalMilliseconds, 2);
            TargetValue = Math.Round(healthCheck.TargetDuration.TotalMilliseconds, 0);
            ObservedUnit = "ms";
            Time = healthCheck.Time;
            Message = healthCheck.Message;

            if (healthCheck.Status != HealthStatus.Healthy && !string.IsNullOrEmpty(healthCheck.Endpoint))
            {
                AffectedEndpoints = new List<string> { healthCheck.Endpoint };
            }

        }

        /// <summary>
        /// Convert the dotnet HealthStatus to the IETF Status
        /// </summary>
        /// <param name="status">HealthStatus (dotnet)</param>
        /// <returns>string</returns>
        public static string ToIetfStatus(HealthStatus status)
        {
            return status switch
            {
                HealthStatus.Healthy => "pass",
                HealthStatus.Degraded => "warn",
                _ => "fail"
            };
        }
    }
}