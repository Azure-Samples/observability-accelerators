# Cargo Processing Tests Scripts

This set of scrips is used to exercise the different features of the Cargo Processing system. It has the following capabilities:

* Generate realistic looking cargo records based on data configured within the ./seed.json file
* Make the cargo data that is generated invalid based on the different validation tests that exist within the cargo-processing-validator logic
* Send large volumes of generated data at the system, that can be configured to randomly invalidate the cargo
* Ensure that the cargo was processed correctly based on the data stored within the operations-api
* Target different entry points within the system (helpful when trying to isolate a specific service for testing of new functionality)
* Trigger chaos within the system TBD
  * Configure the target for the chaos TBD
  * Inject random chaos within a high load test TBD
  * Configure the type of chaos to trigger based on what the target of the chaos is TBD

## Targets

There are 4 different targets for the test cases. As each target needs to have access to different environment specific settings, you may not need to configure all of the settings used by the test scripts. The following describes the different targets the test generators can hit, along with the relevant environment settings for them.

* cargo-processing-api: The only end-to-end test target as it represents sending messages to the ingestion point of the system. As such it has the ability to perform validation tests. The environment settings required to run tests targetting this test generator are:
  * CARGO_PROCESSING_API_URL: The host path for the cargo-processing-api, it is where cargo will be posted to.
  * OPERATIONS_API_URL: The host path for the operation-api, it is where the validation tests will look for the operations detail. This is only required if you've configured the tests to validate the results.
* cargo-processing-validator: This target will post cargo object directly into the ingestion queue that the cargo-processing-validator will read from to process cargo. Based on configuration settings within the test run, this generator will randomly create invalid cargo along with valid cargo. The environment settings required to run tests targeting this test generator are:
  * SERVICE_BUS_CONNECTION_STRING: The connection string to the service bus that the cargo-processing-validator service is listening to
  * QUEUE_NAME: The name of the ingestion queue that the cargo-processing-validator service is listening to
* valid-cargo-manager: This will target just the valid-cargo-manager, bypassing both the cargo-processing-api and the cargo-processing-validator. The cargo objects generated from this step, would pass the validation tests performed by the cargo-processing-validator. The environment settings required to run tests targeting this test generator are:
  * SERVICE_BUS_CONNECTION_STRING: The connection string to the service bus that the valid-cargo-manager service is listening to
  * TOPIC_NAME: The name of the topic that the valid-cargo-manager service is listening to
* invalid-cargo-manager: This will target just the valid-cargo-manager, bypassing both the cargo-processing-api and the cargo-processing-validator. . The cargo objects generated from this step, would pass the validation tests performed by the cargo-processing-validator. The environment settings required to run tests targeting this test generator are:
  * SERVICE_BUS_CONNECTION_STRING: The connection string to the service bus that the valid-cargo-manager service is listening to
  * TOPIC_NAME: The name of the topic that the valid-cargo-manager service is listening to

## Configuration

There are quite a number of toggles that can be used to create the tests. Enough that providing via command lines args can be quite cumbersume. Instead, you have the ability to configure either a single test run, or a suite of test runs, within a single configuration file. The current set of configurations can be found within the ./testConfigurations directory. The details of the structure of the configuration are as follows:

At the top level is a single object named "tests" which is an array of test objects to run. The test object structure is:

* name(string): Used when writing to the console, and constructing the test report.
* target(string): Defines which of the above targets the test will run for
* volume(number): the number of cargo objects to generate for the tests
* validateResults(boolean): instructs the scripts to validate the results of the test (only available when targeting the cargo-processing-api)
* validationDelayInMilliseconds(number): the number of milliseconds the script will delay before validating the test results
* delayBetweenCargoInMilliseconds(number): the number of milliseconds the script will delay between sending each cargo object to the target. No delay is applied if this is set to `0` (the default)
* maxRetries(number): the number of times the scripts will retry a failed validation test
* startingRetryBufferInMilliseconds(number): the number of milliseconds the scripts will delay before retrying the validation. Each retry will double this value, providing a growing backoff period between retries.
* properties(object): key/value properties provided to the generators to assist with their processing. Each generator has the ability to have their own relevant properties. Current properties available are:

| property name | datatype | targets using | implemented | description |
| ------------- | -------- | ------------- | ----------- | ----------- |
| chanceToInvalidate | number | cargo-processing-api, cargo-processing-validator | Yes | Indicates the chance that a generated cargo object will be made invalid. It acts as a 1 in N chance for the cargo to be made invalid. e.g. a value of 0, guarantees none of the cargo will be made invalid, a value of 1 guarantees that all of the cargo will be made invalid, a value of 50 means that there is a 1 in 50 chance that any single cargo object will be made invalid |
| chaosSettings | Array | None | No | Will house the configuration of how the tests will create chaos within the system |

For example the default test that are run when no configuration file is provided when run is this:

``` json
{
    "tests": [
        {
            "name": "End to End Validation of valid cargo",
            "target": "cargo-processing-api",
            "volume": 5,
            "validateResults": true,
            "validationDelayInMilliseconds": 20000,
            "maxRetries": 5,
            "startingRetryBufferInMilliseconds": 300,
            "properties": {
                "chanceToInvalidate": 0
            }
        },
        {
            "name": "End to End Validation of invalid cargo",
            "target": "cargo-processing-api",
            "volume": 5,
            "validateResults": true,
            "validationDelayInMilliseconds": 10000,
            "maxRetries": 5,
            "startingRetryBufferInMilliseconds": 300,
            "properties": {
                "chanceToInvalidate": 1
            }
        }
    ]
}
```

## Running the tests

Once configure you can either run the default tests simply by running the

``` bash
node ./index.js
```

from the command line. You can override this default behavior by by providing an alternative configuration file for your tests. Like so:

``` bash
node ./index.js -c ./testConfigurations/scale.json
```

The console output will provide status of what the scripts are doing while they and provide a summary of each tests results for example:

``` bash
Starting End to End Validation of invalid cargo test.
index.js:23
5 cargo objects generated
generators/cargoProcessingApi.js:15
Sending cargo to: http://20.106.116.247/cargo/a2e5fd80-6c0a-43ba-908c-ea6fad23bb24
generators/cargoProcessingApi.js:41
Sending cargo to: http://20.106.116.247/cargo/42e6c004-f9ad-4f48-97e0-962d9492303f
generators/cargoProcessingApi.js:41
Sending cargo to: http://20.106.116.247/cargo/9863bff4-028c-4e90-84a9-c0e8b5bd5efb
generators/cargoProcessingApi.js:41
Sending cargo to: http://20.106.116.247/cargo/67ee24ed-880a-43cb-ad6c-6f9c43df4465
generators/cargoProcessingApi.js:41
Sending cargo to: http://20.106.116.247/cargo/8732fda3-1f36-444f-bbd7-7ff5ce4c174a
generators/cargoProcessingApi.js:41
2
Giving system time to process the cargo before validating the results
index.js:45
Getting operation details from: http://20.106.116.247/operations/fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2
cargoValidation.js:55
Operation id: fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2 failed validation. 5 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2
cargoValidation.js:55
Operation id: fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2 failed validation. 4 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2
cargoValidation.js:55
Operation id: fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2 failed validation. 3 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2
cargoValidation.js:55
Operation id: fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2 failed validation. 2 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/fc8dd636-d8b2-3fcf-88d5-77a1e34f77e2
cargoValidation.js:55
Getting operation details from: http://20.106.116.247/operations/f74b33e7-b7df-3519-97bf-37ae07d8a9db
cargoValidation.js:55
Getting operation details from: http://20.106.116.247/operations/d80c3a68-dc69-3607-bc1d-4f5eb22106bf
cargoValidation.js:55
Operation id: d80c3a68-dc69-3607-bc1d-4f5eb22106bf failed validation. 5 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/d80c3a68-dc69-3607-bc1d-4f5eb22106bf
cargoValidation.js:55
Operation id: d80c3a68-dc69-3607-bc1d-4f5eb22106bf failed validation. 4 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/d80c3a68-dc69-3607-bc1d-4f5eb22106bf
cargoValidation.js:55
Operation id: d80c3a68-dc69-3607-bc1d-4f5eb22106bf failed validation. 3 retries remaining
cargoValidation.js:44
Getting operation details from: http://20.106.116.247/operations/d80c3a68-dc69-3607-bc1d-4f5eb22106bf
cargoValidation.js:55
Getting operation details from: http://20.106.116.247/operations/0f6d7a74-563d-399d-bb56-49423a5655cf
cargoValidation.js:55
Getting operation details from: http://20.106.116.247/operations/5774754b-7dcf-3503-9d6a-fda7d542c947
cargoValidation.js:55
**********************************************************************************
outputTestResults.js:23
End to End Validation of invalid cargo results: 5 test; 0 failed; 5 succeeded;
outputTestResults.js:24
**********************************************************************************
Detailed Test Results can be viewed at ./testResults/EndtoEndValidationofinvalidcargo-43bff096-5255-4b87-bb82-1f34ede460de.txt
```

For more detailed results of the tests, a test report is provided. The final output line from the test run will provide the file name for the test report.

The test report will contain the same summary information provided in the console, but also what cargo objects were sent, the final operation state for the cargo sent, and a break down of which validation tests passed/failed.

### Experimenting with test configuration

As well as loading the test configuration from a file, you can also specify the test configuration via stdin.
This is useful when you want to experiment with different test configurations without having to modify the test configuration file.

The command below shows an example of how to specify the test configuration via stdin:

```bash
cat << EOF | node index.js -c -
{
    "tests": [
        {
            "name": "Send cargo to cargo processing api",
            "target": "cargo-processing-api",
            "volume": 50,
            "validateResults": false,
            "delayBetweenCargoInMilliseconds": 5000,
            "startingRetryBufferInMilliseconds": 300,
            "properties": {
                "chanceToInvalidate": 0
            }
        }
    ]
}
EOF
```

## Creating Chaos

Built into the tests is the ability to trigger chaos within the services. This is functionality intended to ensure our observability and monitoring solutions are capable of finding and potentially guarding against known failures that could occur. To create a chaos within a test run, you will need to add chaosSettings within the properties of the test.

A chaos setting is made up of the following values:

* Target: The service that will end up causing chaos. In the context of this solution space, the values map to the names of the different services. cargo-processing-api, cargo-processing-validator, invalid-cargo-manager, valid-cargo-manager and operations-api.
* Type: Each service has it's own types and variety of chaos that can be let lose on it. Below is a table describing what types of chaos are available.
* isEnabled: indicates if the chaosSetting will actually stand a chance of being triggered.
* chanceToCauseChaos: Works similarly to the chanceToInvalidate variable fo the test configuration. It acts as a 1 in N chance for the chaos to be triggered. e.g. a value of 0, guarantees none of the cargo will trigger chaos, a value of 1 guarantees that all of the cargo will trigger this type of chaos, a value of 50 means that there is a 1 in 50 chance that any single cargo object will trigger the chaos

### Types of chaos

The below table defines the different types of chaos that can be created within these services.

| Target                     | Type                   | Description                                                                                                                                              | Notes                                                                                                                                                                                  |
| -------------------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cargo-processing-api       | operations-api-failure | Will cause a chaos exception to occur when the cargo-processing-api attempts to call the operations-api.                                                 | This will cause the put/post request to receive a INTERNAL SERVER ERROR response, but the api should continue to function.                                                             |
| cargo-processing-api       | process-ending         | Will cause the cargo-processing-api to shut down                                                                                                         |                                                                                                                                                                                        |
| cargo-processing-api       | service-bus-failure    | Will cause the service to close the service-bus connection right before it attempts to use it.                                                           |                                                                                                                                                                                        |
| cargo-processing-api       | invalid-schema         | Will cause the test script to modify the cargo object being sent in away that causes the cargo-processing-api to throw an invalid json schema exception. |                                                                                                                                                                                        |
| cargo-processing-validator | service-bus-failure    | Will cause the service to close the service-bus connection right before it attempts to use it.                                                           |                                                                                                                                                                                        |
| cargo-processing-validator | process-killing        | Will cause the cargo-processing-validator to shut down                                                                                                   |                                                                                                                                                                                        |
| cargo-processing-validator | invalid-schema         | Sends a message that is missing it's demandDates directly to the ingest-cargo queue                                                                      | In order to bypass the APIs validation checks, the message must be injected directly into the queue to trigger the dead letter effect of an invalid schema being sent to the validator |

### Sample Chaos

The [cargo_processing_api_chaos_tests](./testConfigurations/cargo_processing_api_chaos_tests.json) file has settings that allow you to create specific chaos events. Each chaos type has been configured to always trigger, when enabled. By default all of the chaos settings have been disabled. Changing the isEnabled to true on one of them will test that specific chaos type. The launch.json has been configured with a debug options for running the test scripts with that specific configuration.
