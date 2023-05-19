const seedData = require('./seed.json');
const crypto = require('crypto');
const addDays = require('date-fns/addDays');

generateBaseCargoObject = function () {
    return {
        id: crypto.randomUUID(),
        product: getProduct(),
        demandDates: getDemandDates(),
        port: getPorts()
    }
}

getProduct = function () {
    return {
        name: getRandomValue(seedData.products),
        quantity: getRandomNumber(10000) + 1
    };
}

getPorts = function () {
    const source = getRandomValue(seedData.ports);
    let destination = getRandomValue(seedData.ports);
    while (destination == source) {
        destination = getRandomValue(seedData.ports);
    }
    return {
        source, destination
    }
}

getDemandDates = function () {
    const today = new Date();

    // Random day within the next 2 weeks
    const startDaysFromToday = getRandomNumber(14) + 1;
    // Random day, after the start date, within 60 days of today, and no more than 30 days from start
    let endDaysFromStart = getRandomNumber(60 - startDaysFromToday) + 1;
    endDaysFromStart = endDaysFromStart >= 30 ? 29 : endDaysFromStart;

    const start = addDays(today, startDaysFromToday);
    const end = addDays(start, endDaysFromStart);

    return { start, end };
}

getRandomValue = function (from) {
    return from[getRandomNumber(from.length)];
}

getRandomNumber = function (max) {
    //Will return a random number between 0 and (max - 1)
    return Math.floor(Math.random() * max);
}

randomYesOrNo = function (chance) {
    // No point in any of the rest of the processing if there is no chance of returning a true result
    if (chance == 0) return false;
    // No point in any of the rest of the processing if there is a guarentee in return a true
    if (chance == 1) return true;
    return (getRandomNumber(chance) + 1) % chance == 0;
}

makeInvalid = function (cargo, includeValidationObject, failureReason) {
    if (failureReason === undefined) {
        failureReason = getRandomNumber(4) + 1;
    }
    let failureMessage = '';
    switch (failureReason) {
        case 1:
            // Make the dates occurr in the past
            failureMessage = 'Start and end dates must be in future.';
            const reduceBy = -70;
            cargo.demandDates.start = addDays(cargo.demandDates.start, reduceBy);
            cargo.demandDates.end = addDays(cargo.demandDates.end, reduceBy);
            if (includeValidationObject) {
                cargo.valid = false;
                cargo.errorMessage = failureMessage;
            }

            break;
        case 2:
            // Make the dates occurr way in the future
            failureMessage = 'Start date cannot be more than 60 days in future.';
            const increaseBy = 70;
            cargo.demandDates.start = addDays(cargo.demandDates.start, increaseBy);
            cargo.demandDates.end = addDays(cargo.demandDates.end, increaseBy);
            if (includeValidationObject) {
                cargo.valid = false;
                cargo.errorMessage = failureMessage;
            }
            break;
        case 3:
            // Make the gap between the dates greater than 30 days
            failureMessage = 'Range between start and end dates cannot exceed 30 days.';
            cargo.demandDates.end = addDays(cargo.demandDates.end, 30);
            if (includeValidationObject) {
                cargo.valid = false;
                cargo.errorMessage = failureMessage;
            }
            break;
        case 4:
            // Flip the dates
            failureMessage = 'End date must be after start date.';
            const tempDate = cargo.demandDates.start;
            cargo.demandDates.start = cargo.demandDates.end;
            cargo.demandDates.end = tempDate;
            if (includeValidationObject) {
                cargo.valid = false;
                cargo.errorMessage = failureMessage;
            }
            break;
    }

    return failureMessage;
}

addToEnvelope = function (cargo) {
    cargo.timestamp = new Date();
    return {
        operationId: crypto.randomUUID(),
        data: cargo
    }
}

toServiceBusMessage = function (envelope, isValid) {
    const message = {
        body: envelope,
        applicationProperties: {
            'Diagnostic-Id': `00-${generateOpenTelemetryId(32)}-${generateOpenTelemetryId(16)}-01`
        }
    }

    if (isValid !== undefined) {
        message.applicationProperties.valid = isValid;
    }
    return message;
}

function generateOpenTelemetryId(length) {
    // must satisfy regex for ids - https://github.com/open-telemetry/opentelemetry-js/blob/0f178d1e2e9b3aed81789820944452c153543198/api/src/trace/spancontext-utils.ts#L22
    const chars = 'abcdef1234567890';
    const randomArray = Array.from(
        { length: length },
        () => chars[getRandomNumber(chars.length)]
    );
    return randomArray.join('');
}

function raiseChaos(resultDetails, cargo, chaosSetting) {
    if (resultDetails.chaosSetting !== undefined) {
        // Chaos already set for this cargo, no need to get CRAZY here
        return;
    }
    resultDetails.chaosSetting = chaosSetting;
    cargo.port.source = chaosSetting.target;
    cargo.port.destination = chaosSetting.type;
    if (chaosSetting.type == "invalid-schema") {
        cargo.demandDates = undefined;
    }
}

async function delay(milliseconds) {
    await new Promise(resolve => setTimeout(resolve, milliseconds));
}

module.exports = {
    generateBaseCargoObject, makeInvalid, addToEnvelope, toServiceBusMessage,
    getRandomNumber, getDemandDates, getPorts, randomYesOrNo, delay, raiseChaos
}
