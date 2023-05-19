# Introducing Chaos

Chaos engineering involves intentionally introducing failures to assess resilience and identify potential weaknesses in an application. Controlled experiments are conducted to understand how the application behaves in unexpected situations. Development teams can identify proper mitigation techniques for real-world scenarios _before_ they occur in production. Chaos engineering is closely tied with the concepts of observability and monitoring - system behavior must be accurately measured over time to understand how it responds to various failure scenarios. Introduction of chaos into the cargo processing application allows us to test the alerting and visualization functionality included in the project, as well as use those same tools to determine best case mitigation techniques for a set of fault scenarios that the team expects the application to handle gracefully.

Azure offers [Azure Chaos Studio](https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview) as a tool to inject common fault scenarios into the application, like CPU/memory pressure or downed nodes in a cluster. Rather than use Chaos Studio, we elected add chaos into the application code directly, in both the `cargo-processing-api` and `cargo-processing-validator` services, with built in integration with our existing load test scripts.

The [cargo-test-scripts](../src/cargo-test-scripts/) folder includes a JavaScript based application used to send requests to the `cargo-processing-api` ingress endpoint or to downstream services directly. Tests are supplied via [json based test run configurations](../src/cargo-test-scripts/testConfigurations/valid_tests.json) that send a configurable number of requests to specific target services. Importantly, `properties.chaosSettings` is available on tests that target the `cargo-processing-api` and `cargo-processing-validator` services, with a set of available `type` options that cause specific fault scenarios in those services:

| Target                     | Type                   | Description                                                                                                                                               |
| -------------------------- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| cargo-processing-api       | operations-api-failure | Will cause a chaos exception to occur when the cargo-processing-api attempts to call the operations-api.                                                  |
| cargo-processing-api       | process-ending         | Will cause the cargo-processing-api to shut down.                                                                                                         |
| cargo-processing-api       | service-bus-failure    | Will cause the service to close the service-bus connection right before it attempts to use it.                                                            |
| cargo-processing-api       | invalid-schema         | Will cause the test script to modify the cargo object being sent in a way that causes the cargo-processing-api to throw an invalid json schema exception. |
| cargo-processing-validator | service-bus-failure    | Will cause the service to close the service-bus connection right before it attempts to use it.                                                            |
| cargo-processing-validator | process-killing        | Will cause the cargo-processing-validator to shut down.                                                                                                   |
| cargo-processing-validator | invalid-schema         | Sends a message that is missing its demandDates directly to the ingest-cargo queue.                                                                       |

The test scripts use a [raiseChaos utility function](../src/cargo-test-scripts/dataBuilderUtils.js) that sets a cargo object's `source` port to the `target` and `destination` port to the `type` specified above in a chaos test. The services themselves are configured to execute fault scenarios when the source and destination ports match these known strings. The `cargo-processing-validator` service contains a [ChaosMonkey](../src/cargo-processing-validator/src/chaos/ChaosMonkey.ts) class that determines whether to cause chaos based on the source and destination ports. It includes [ProcessEnding](../src/cargo-processing-validator/src/chaos/ProcessEndingMonkey.ts) and [ServiceBusKilling](../src/cargo-processing-validator/src/chaos/ServiceBusKillingMonkey.ts) classes that exit the running process or close the existing service bus connection, respectively. If the `source` port for a cargo object is set to `cargo-processing-validator` and `destination` port is set to `process-killing`, the `ProcessEndingMonkey` will initialize and exit the current process, for example. The `cargo-processing-api` service has similar ChaosMonkey implementations.

The chaos tests should cause internal exceptions, restarts, and health check issues that should immediately surface in alerts (detailed below). Workbook tiles (detailed below) should illuminate how the application performed over the test run, displaying increases in request duration, dead-lettered messages, and other indicators of application health. To run a chaos test, open the [cargo-test-scripts](../src/cargo-test-scripts/) folder in its dedicated dev container. The folder contains a number of [pre-defined test configurations](../src/cargo-test-scripts/testConfigurations/) that includes a [`cargo_processing_api_chaos_tests.json`](../src/cargo-test-scripts/testConfigurations/cargo_processing_api_chaos_tests.json) configuration. From the terminal in the dev container, run the following command to trigger each of the types of fault scenarios listed above:

```bash
node ./index.js -c ./testConfigurations/cargo_processing_api_chaos_tests.json
```