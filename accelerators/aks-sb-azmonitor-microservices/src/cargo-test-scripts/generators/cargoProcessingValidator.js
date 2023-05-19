const dataBuilderUtil = require('../dataBuilderUtils.js');
const ServiceBusClient = require('@azure/service-bus').ServiceBusClient;
const config = require('../config.js');

class CargoProcessingValidatorGenerator {
    constructor(properties) {
        this.properties = properties;
        this.canValidateResults = false;
    }

    async run(count) {
        const cargoMessageBodies = this.generateCargoToSend(count);
        console.log(`${cargoMessageBodies.length} cargo objects created`);
        const sbClient = new ServiceBusClient(config.serviceBusConnectionString);
        const sender = sbClient.createSender(config.queueName);
        const cargoSent = [];
        try {
            let batch = await sender.createMessageBatch();
            for (let i = 0; i < cargoMessageBodies.length; i++) {
                const cargoToSend = cargoMessageBodies[i];
                const message = { body: cargoToSend.cargo };
                // try to add the message to the batch
                if (!batch.tryAddMessage(message)) {
                    // Couldn't add more to the batch, sending what we have, then starting a new batch
                    console.log(`Sending batch of ${batch.count} cargo objects`);
                    await sender.sendMessages(batch);

                    // create a new batch 
                    batch = await sender.createMessageBatch();

                    // now, add the message failed to be added to the previous batch to this batch
                    if (!batch.tryAddMessage(message)) {
                        // if it still can't be added to the batch, the message is to big
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
            let cargo = dataBuilderUtil.generateBaseCargoObject();
            const resultDetails = { isValid: true };
            //Randomly make the cargo invalid
            this.randomlyMakeInvalid(resultDetails, cargo);
            this.addSomeChaos(resultDetails, cargo)

            return {
                cargo: dataBuilderUtil.addToEnvelope(cargo),
                resultDetails
            };
        });
    }

    randomlyMakeInvalid(resultDetails, cargo) {
        if (dataBuilderUtil.randomYesOrNo(this.properties.chanceToInvalidate)) {
            resultDetails.failureReason = dataBuilderUtil.makeInvalid(cargo, false);
            resultDetails.isValid = false;
        }
    }

    addSomeChaos(resultDetails, cargo) {
        if (this.properties.chaosSettings === undefined) return;
        var activeChaos = this.properties.chaosSettings.filter(chaosSetting => chaosSetting.isEnabled);
        activeChaos.forEach(chaosSetting => {
            if (dataBuilderUtil.randomYesOrNo(chaosSetting.chanceToCauseChaos)) {
                dataBuilderUtil.raiseChaos(resultDetails, cargo, chaosSetting);
            }
        });
    }
}

module.exports = { default: CargoProcessingValidatorGenerator };
