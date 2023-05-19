const dataBuilderUtil = require('../dataBuilderUtils.js');
const ServiceBusClient = require('@azure/service-bus').ServiceBusClient;
const config = require('../config.js');

class ValidatedCargoManagerGenerator {
    constructor(isValid, properties) {
        this.isValid = isValid;
        this.properties = properties;
        this.canValidateResults = false;
    }

    async run(count) {
        const cargoMessageBodies = this.generateCargoToSend(count);
        console.log(`${cargoMessageBodies.length} cargo objects created`);
        const sbClient = new ServiceBusClient(config.serviceBusConnectionString);
        const sender = sbClient.createSender(config.topicName);
        const cargoSent = [];
        try {
            let batch = await sender.createMessageBatch();
            for (let i = 0; i < cargoMessageBodies.length; i++) {
                const cargoToSend = cargoMessageBodies[i];
                // try to add the message to the batch
                if (!batch.tryAddMessage(cargoToSend.cargo)) {
                    // Couldn't add more to the batch, sending what we have, then starting a new batch
                    console.log(`Sending batch of ${batch.count} cargo objects`);
                    await sender.sendMessages(batch);

                    // create a new batch 
                    batch = await sender.createMessageBatch();

                    // now, add the message failed to be added to the previous batch to this batch
                    if (!batch.tryAddMessage(cargoToSend.cargo)) {
                        // if it still can't be added to the batch, the message is probably too big to fit in a batch
                        throw new Error("Message too big to fit in a batch");
                    }
                }
                cargoSent.push({
                    id: cargoToSend.cargo.id,
                    resultDetails: cargoToSend.resultDetails
                });
            }

            console.log(`Sending batch of ${batch.count} cargo objects`);
            await sender.sendMessages(batch);
        }
        finally {
            sender.close();
            sbClient.close();
        }
        return cargoSent;
    }

    generateCargoToSend(count) {
        return [...Array(count).keys()].map(() => {
            const cargo = dataBuilderUtil.generateBaseCargoObject();
            const resultDetails = {
                isValid
            }
            if (this.isValid) {
                cargo.valid = true;
                cargo.errorMessage = null;
            } else {
                resultDetails.failureReason = dataBuilderUtil.makeInvalid(cargo, true);
            }
            return {
                cargo: dataBuilderUtil.toServiceBusMessage(addToEnvelope(cargo), this.isValid),
                resultDetails
            };
        });
    }
}

module.exports = { default: ValidatedCargoManagerGenerator };
