const dataBuilderUtil = require('../dataBuilderUtils.js');
const config = require('../config.js');
const axios = require('axios');
const path = require('path');
const URL = require('node:url').URL;

class CargoProcessingApiGenerator {
    constructor(properties) {
        this.properties = properties;
        this.canValidateResults = true;
    }

    async run(count, delay) {
        const cargo = this.generateCargoToSend(count);
        console.log(`${cargo.length} cargo objects generated`);
        if (delay === 0) {
            return await Promise.all(cargo.map(this.putCargo));
        } else {
            const result = []
            for (const cargoToSend of cargo) {
                await this.putCargo(cargoToSend);
                result.push(await dataBuilderUtil.delay(delay));
            }
            return result;
        }
    }

    generateCargoToSend(count) {
        return [...Array(count).keys()].map(() => {
            const cargo = dataBuilderUtil.generateBaseCargoObject();
            const resultDetails = { isValid: true, state: "Succeeded" };
            this.randomlyMakeInvalid(resultDetails, cargo);
            this.addSomeChaos(resultDetails, cargo)

            return {
                cargo,
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

    async putCargo(cargoToSend, retries = 3, backoff = 300) {
        const retryCodes = [408, 500, 502, 503, 504, 522, 524] /* 2 */
        const cargo = cargoToSend.cargo;
        try {
            const route = new URL(path.join('cargo', cargo.id), config.cargoProcessingApiUrl);
            console.log(`Sending cargo to: ${route} (dest port: ${cargo.port.destination})`);
            const res = await axios.put(route, cargo);
            const statusCode = res.status;
            if (statusCode < 200 || statusCode > 299) {
                if (retries > 0 && retryCodes.includes(statusCode)) {
                    //Non-blocking sleep
                    await dataBuilderUtil.delay(backoff);
                    return await this.putCargo(cargoToSend, retries - 1, backoff * 2);
                } else {
                    throw (Error(res));
                }
            }
            return {
                operationId: res.headers.get('operation-id'),
                cargo,
                resultDetails: cargoToSend.resultDetails
            }
        } catch (ex) {
            console.error(ex);
        }
    }
}

module.exports = { default: CargoProcessingApiGenerator };
