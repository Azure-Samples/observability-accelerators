const dataBuilderUtil = require('./dataBuilderUtils.js');
const parseArgs = require('node:util').parseArgs;
const CargoProcessingApiGenerator = require('./generators/cargoProcessingApi.js').default;
const CargoProcessingValidatorGenerator = require('./generators/cargoProcessingValidator.js').default;
const ValidatedCargoManagerGenerator = require('./generators/validatedCargoManagers.js').default;
const CargoValidation = require('./cargoValidation.js').default
const displayTestResults = require('./outputTestResults.js').displayTestResults;
const { v4: uuidv4 } = require('uuid');
const fs = require('node:fs');
const runId = uuidv4();

const options = {
    'config': { type: 'string', short: 'c', default: "./testConfigurations/valid_tests.json" },
};

const { values } = parseArgs({ options, tokens: false });

const configSource = values.config === "-" ? 0 : values.config; // Read from stdin if config is "-"
const config = JSON.parse(fs.readFileSync(configSource, 'utf8'));

let testsFailed = false;

for (const test of config.tests) {
    console.log(`Starting ${test.name} test.`)
    let generator = null;
    switch (test.target) {
        case 'cargo-processing-api':
            generator = new CargoProcessingApiGenerator(test.properties);
            break;
        case 'cargo-processing-validator':
            generator = new CargoProcessingValidatorGenerator(test.properties);
            break;
        case 'valid-cargo-manager':
            generator = new ValidatedCargoManagerGenerator(true, test.properties);
            break;
        case 'invalid-cargo-manager':
            generator = new ValidatedCargoManagerGenerator(false, test.properties);
            break;
    }

    (async function () {
        const testVolume = parseInt(test.volume);
        if (testVolume == 0) {
            console.log("Volume configured for 0 tests, exiting test");
            return;
        }

        const cargoSent = [...await generator.run(parseInt(test.volume), parseInt(test.delayBetweenCargoInMilliseconds ?? 0))];
        if (test.validateResults && generator.canValidateResults) {
            const validationResults = [];
            const cargoValidator = new CargoValidation();
            console.log('Giving system time to process the cargo before validating the results');

            await dataBuilderUtil.delay(test.validationDelayInMilliseconds);
            for (const cargo of cargoSent) {
                validationResults.push(
                    await cargoValidator.validate(cargo, test.maxRetries, test.startingRetryBufferInMilliseconds)
                );
            }
            await displayTestResults(validationResults, test.name, runId);
        }

    })();
};

if (testsFailed) {
    process.exit(1);
}
