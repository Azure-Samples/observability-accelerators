const dataBuilderUtil = require('./dataBuilderUtils.js');
const config = require('./config.js');
const axios = require('axios');
const path = require('path');
const URL = require('node:url').URL;

class CargoValidation {
    async validate(cargoSent, retries, buffer) {
        const operation = await this.getOperationInformation(cargoSent.operationId);
        const validationResults = { testDetails: { cargo: { ...cargoSent }, operation: { ...operation } } };

        if (operation == undefined) {
            validationResults.operationFound = false;
            // Giving the services more time to populate the operation
            return await this.retryValidation(cargoSent, validationResults, retries, buffer);
        }

        validationResults.operationFound = true;
        validationResults.stateCorrect = operation.state != undefined && operation.state == cargoSent.resultDetails.state;

        if (!validationResults.stateCorrect) {
            // State isn't correct
            // Giving the services more time to finish processing the operation
            return await this.retryValidation(cargoSent, validationResults, retries, buffer);
        }

        // State is what is expected, no more retries, services have processed to the expected state,
        // Any incorrect values from here due to services not processing he cargo the way the tests expected them to
        validationResults.resultPopulated = !(operation.result == null || operation.result == undefined);
        validationResults.correctCargoId = cargoSent.cargo.id == operation.result.id;
        validationResults.validFieldIsCorrect = cargoSent.resultDetails.isValid == operation.result.valid;
        if (cargoSent.resultDetails.isValid == false) {
            validationResults.correctErrorMessage =
                operation.result.errorMessage == cargoSent.resultDetails.failureReason
        }

        return validationResults;
    }

    async retryValidation(cargoSent, validationResults, retries, buffer) {
        if (retries <= 0) {
            return validationResults;
        }
        console.log(`Operation id: ${cargoSent.operationId} failed validation. ${retries} retries remaining`);

        await dataBuilderUtil.delay(buffer);

        return await this.validate(cargoSent, retries - 1, buffer * 2);
    }

    async getOperationInformation(id, retries = 3, backoff = 300) {
        const retryCodes = [408, 500, 502, 503, 504, 522, 524] /* 2 */
        try {
            const route = new URL(path.join('operations', id), config.operationsApiUrl).toString();
            console.log(`Getting operation details from: ${route}`);
            const res = await axios.get(route);
            const statusCode = res.status;
            if (statusCode < 200 || statusCode > 299) {
                if (retries > 0 && retryCodes.includes(statusCode)) {
                    //Non-blocking sleep
                    await dataBuilderUtil.delay(backoff);
                    return await this.getOperationInformation(id, retries - 1, backoff * 2);
                } else {
                    throw (Error(res));
                }
            }
            return res.data;

        } catch (ex) {
            console.error(ex);
        }
    }
}

module.exports = { default: CargoValidation };
