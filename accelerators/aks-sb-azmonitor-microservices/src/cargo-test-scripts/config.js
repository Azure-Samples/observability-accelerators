require('dotenv').config();

serviceBusConnectionString = process.env.SERVICE_BUS_CONNECTION_STRING;
queueName = process.env.QUEUE_NAME;
topicName = process.env.TOPIC_NAME;
cargoProcessingApiUrl = process.env.CARGO_PROCESSING_API_URL;
operationsApiUrl = process.env.OPERATIONS_API_URL;

module.exports = {
    serviceBusConnectionString, queueName, topicName, cargoProcessingApiUrl, operationsApiUrl
}
