namespace ValidCargoProcessor.HealthCheck
{
    using System.Diagnostics;
    using System.Globalization;
    using Microsoft.Extensions.Diagnostics.HealthChecks;
    using ValidCargoProcessor.HealthCheck.Models;

    public class HealthCheckResultBuilder
    {
        private string TimeoutMessage = "Request exceeded expected duration";
        private HealthStatus _status = HealthStatus.Healthy;
        private string _componentId = string.Empty;
        private string _componentType = string.Empty;
        private TimeSpan _duration;
        private TimeSpan _targetDuration;
        private string _time = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ", CultureInfo.InvariantCulture);
        private string _endpoint = String.Empty;
        private string _message = String.Empty;
        private Stopwatch stopwatch = new();

        public HealthCheckResultBuilder()
        {
            stopwatch.Start();
        }

        public HealthCheck build()
        {
            if (stopwatch.IsRunning)
            {
                stopwatch.Stop();
            }

            this._duration = stopwatch.Elapsed;

            HealthCheck result = new()
            {
                Endpoint = this._endpoint,
                Status = this._status,
                Duration = stopwatch.Elapsed,
                TargetDuration = this._targetDuration,
                ComponentId = this._componentId,
                ComponentType = this._componentType,
            };

            // check duration
            if (result.Duration.TotalMilliseconds > this._targetDuration.TotalMilliseconds)
            {
                result.Status = HealthStatus.Degraded;
                result.Message = this.TimeoutMessage;
            }

            return result;
        }

        public HealthCheckResultBuilder StartTimer()
        {
            this.stopwatch.Restart();
            return this;
        }

        public HealthCheckResultBuilder StopTimer()
        {
            this.stopwatch.Stop();
            return this;
        }

        public HealthCheckResultBuilder Endpoint(string endpoint)
        {
            this._endpoint = endpoint;
            return this;
        }

        public HealthCheckResultBuilder Message(string message)
        {
            this._message = message;
            return this;
        }

        public HealthCheckResultBuilder ComponentId(string componentId)
        {
            this._componentId = componentId;
            return this;
        }

        public HealthCheckResultBuilder ComponentType(string componentType)
        {
            this._componentType = componentType;
            return this;
        }

        public HealthCheckResultBuilder Status(HealthStatus status)
        {
            this._status = status;
            return this;
        }

        public HealthCheckResultBuilder TargetDurationMs(int targetDurationMs)
        {
            this._targetDuration = new System.TimeSpan(0, 0, 0, 0, (int)targetDurationMs);
            return this;
        }

        public HealthCheckResultBuilder Exception(Exception ex)
        {
            if (ex != null)
            {
                this._status = HealthStatus.Unhealthy;
                this._message = ex.Message;
                this.StopTimer();
            }
            return this;
        }
    }

}