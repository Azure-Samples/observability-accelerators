namespace ValidCargoProcessor
{
    using Newtonsoft.Json;

    public class ValidCargo
    {
        [JsonProperty(PropertyName = "timestamp")]
        public string Timestamp { get; set; } = String.Empty;
        [JsonProperty(PropertyName = "id")]
        public string Id { get; set; } = String.Empty;
        [JsonProperty(PropertyName = "product")]
        public Product Product { get; set; } = new Product();
        [JsonProperty(PropertyName = "port")]
        public Port Port { get; set; } = new Port();
        [JsonProperty(PropertyName = "demandDates")]
        public DemandDates DemandDates { get; set; } = new DemandDates();
        [JsonProperty(PropertyName = "valid")]
        public bool Valid { get; set; }
        [JsonProperty(PropertyName = "errorMessage")]
        public string ErrorMessage { get; set; } = String.Empty;
    }

    public class DemandDates
    {
        [JsonProperty(PropertyName = "start")]
        public string Start { get; set; } = String.Empty;
        [JsonProperty(PropertyName = "end")]
        public string End { get; set; } = String.Empty;
    }

    public class Port
    {
        [JsonProperty(PropertyName = "source")]
        public string Source { get; set; } = String.Empty;
        [JsonProperty(PropertyName = "destination")]
        public string Destination { get; set; } = String.Empty;
    }

    public class Product
    {
        [JsonProperty(PropertyName = "name")]
        public string Name { get; set; } = String.Empty;
        [JsonProperty(PropertyName = "quantity")]
        public int Quantity { get; set; }
    }

    public class MessageEnvelope
    {
        [JsonProperty(PropertyName = "operationId")]
        public string? OperationId { get; set; }
        [JsonProperty(PropertyName = "data")]
        public ValidCargo Data { get; set; } = new ValidCargo();
    }
}
