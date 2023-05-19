namespace ValidCargoProcessor
{
    using Newtonsoft.Json;
    public class OperationState
    {
        [JsonProperty(PropertyName = "operationId")]
        public string? OperationId { get; set; }
        [JsonProperty(PropertyName = "state")]
        public string? State { get; set; }
        [JsonProperty(PropertyName = "result")]
        public ValidCargo? Result { get; set; }
        [JsonProperty(PropertyName = "error")]
        public string? Error { get; set; }
    }
}