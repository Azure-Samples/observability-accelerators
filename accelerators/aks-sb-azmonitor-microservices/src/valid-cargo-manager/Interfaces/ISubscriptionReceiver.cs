namespace ValidCargoProcessor
{

    public interface ISubscriptionReceiver
    {
        Task ProcessMessagesAsync();

        Task StopProcessingAsync();

        Task AddItemToContainerAsync(ValidCargo cargo);
    }
}