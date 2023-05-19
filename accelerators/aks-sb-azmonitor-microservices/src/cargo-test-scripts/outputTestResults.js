const fs = require('fs/promises');

async function displayTestResults(validationResults, testName, runId) {
    const successfulResults = [];
    const failedResults = [];
    for (const result of validationResults) {
        var failed = false;
        for (const key of Object.keys(result)) {
            if (key == "testDetails") {
                continue;
            }
            if (result[key] == false) {
                failedResults.push(result);
                failed = true;
                continue;
            }
        }
        if (!failed) {
            successfulResults.push(result);
        }
    }

    console.log(`**********************************************************************************`);
    console.log(`${testName} results: ${validationResults.length} test; \x1b[31m${failedResults.length} failed\x1b[0m; ${successfulResults.length} succeeded; `);
    console.log(`**********************************************************************************`);

    await saveTestReport(testName, validationResults, failedResults, successfulResults, runId)
}

async function saveTestReport(testName, validationResults, failedResults, successfulResults, runId) {
    const testReportDirectory = "testResults";
    await createDirectory(testReportDirectory);

    const fileName = `./${testReportDirectory}/${testName.replaceAll(' ', '')}-${runId}.txt`;
    await fs.writeFile(fileName, "");
    await fs.appendFile(fileName, `**********************************************************************************\n`);
    await fs.appendFile(fileName, `${testName} results: ${validationResults.length} test; ${failedResults.length} failed; ${successfulResults.length} succeeded;\n`);
    await fs.appendFile(fileName, `**********************************************************************************\n`);

    if (failedResults.length > 0) {
        testsFailed = true;
        await fs.appendFile(fileName, `\nFailed Results\n`);
        await fs.appendFile(fileName, `----------------------------------------------------------------------------------\n`);
        await fs.appendFile(fileName, `${JSON.stringify(failedResults, null, 2)}\n`);
    }
    if (successfulResults.length > 0) {
        await fs.appendFile(fileName, `\nSuccessful Results:\n`);
        await fs.appendFile(fileName, `----------------------------------------------------------------------------------\n`);
        await fs.appendFile(fileName, JSON.stringify(successfulResults, null, 2));
    }
    console.log(`Detailed Test Results can be viewed at ${fileName}`)
}

async function createDirectory(path) {
    try {
        await fs.access(path);
    } catch (error) {
        console.log(error);
        await fs.mkdir(path);
    }
}

module.exports = {
    displayTestResults
}