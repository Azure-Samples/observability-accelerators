# Health Checks

Monitoring and quickly responding to changes in service health is crucial for distributed applications deployed to an AKS environment. Health checks report the internal status of a microservice at regular intervals and are used by orchestrators, like Kubernetes, to determine if each service is functioning properly. Health checks should examine connections to databases and other dependencies and can report health based on memory usage, CPU utilization, network connectivity, or any other key performance indicators that are critical to the functioning of the microservice. Essentially, a health check should verify that the microservice is able to perform its intended function and that it is not experiencing any critical errors or failures. AKS automatically triggers these health checks and acts upon pods that report back unhealthy.

Health check functionality is often exposed via HTTP endpoints, but Kubernetes supports consumption of TCP and gRPC endpoints as well and is also capable of running `exec` commands exposed by pods. Kubernetes consumes the endpoints or commands via [3 types of probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) - startup, readiness, and liveness probes. Startup probes run after deployment and make the kubelet agent aware that the containers in the pod have started. Kubernetes will not start readiness and liveness probes until the startup probe reports success. Readiness probes alert Kubernetes that the pod is ready to accept traffic and liveness probes are subsequently used to regularly check that the pod is healthy. Pods that fail liveness probes are automatically restarted by AKS to fix ephemeral issues. While different endpoints or commands can be used for each probe type, we elected to reuse the same health check endpoints in our services, declared via the helm charts that deploy the services to AKS.

Services like the `cargo-processing-api` and `operations-api`, which are Spring Boot apps that already expose HTTP endpoints, are easy candidates to expose health checks via HTTP endpoint. `spring-boot-starter-actuator` used in these projects is capable of [exposing a `/health` endpoint](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html#actuator.endpoints) that reports internal application health using indicators like [dependency connections and disk space](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html#actuator.endpoints.health.auto-configured-health-indicators). The endpoint is configured via the [application.properties](../src/cargo-processing-api/src/main/resources/application.properties) file:

```java
management.endpoints.web.exposure.include=health,info
endpoints.health.sensitive=false
management.endpoint.health.show-details=always
```

The `/actuator/health` endpoint that Spring Boot spins up is declared within the helm charts for those services:

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 20
  failureThreshold: 3
  timeoutSeconds: 10
```

The `cargo-processing-validator`, `valid-cargo-manager`, and `invalid-cargo-manager` are background worker services that do not already expose HTTP endpoints. The `cargo-processing-validator` and `invalid-cargo-manager` do not include explicit health checks. Instead, they are designed to [self-destruct](../src/cargo-processing-validator/src/index.ts) when errors occur. These services restart via error when failed dependency connections arise, rather than failed liveness probes that would result from those same connections. In contrast, we elected to demonstrate TCP health check functionality on the `valid-cargo-manager`. A [HealthCheckController](../src/valid-cargo-manager/Controllers/HealthCheckController.cs) that starts a TCP server is added to the list of [services configured during startup](../src/valid-cargo-manager/Program.cs). The controller uses [CosmosDBHealthChecker](../src/valid-cargo-manager/HealthCheck/CosmosDbHealthChecker.cs) and [ServiceBusHealthChecker](../src/valid-cargo-manager/HealthCheck/ServiceBusHealthChecker.cs) classes to report status of connection to those dependent services. The exposed TCP port and other configuration details are set via the [appsettings.json file](../src/valid-cargo-manager/appsettings.sample.json):

```json
"HealthCheck": {
    "TcpServer": {
      "Port": 3030
    },
    "CosmosDB": {
      "MaxDurationMs": 200
    },
    "ServiceBus": {
      "MaxDurationMs": 200
    }
}
```

The TCP socket that the service exposes is then declared within its helm chart:

```yaml
livenessProbe:
  tcpSocket:
    port: 3030
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 10
```

Kubernetes automatically consumes these endpoints and will take action on a pod if a probe fails, like a pod restart if a liveness probe fails. The calls to these endpoints can be viewed in the Logs window, via the `requests` table:

```sql
requests
| where cloud_RoleName == "cargo-processing-api" and url contains "/health"
```

![Health check logs](../assets/health-check-logs.png)

While Kubernetes will automatically respond to these events, the application additionally includes alerts that proactively notifies admins about issues related to health checks so they can take additional action to debug, if necessary. Each microservice has a health check failure and health check not reporting alert that consumes the same logs used above, as well as a pod restart alert triggered when a service pod restarts more than once within 5 minutes.
Health checks often fail due to ephemeral issues that can be resolved by automatic Kubernetes actions, like a pod restart, but other underlying issues may require human intervention. Alerts offer an additional monitoring layer that serves to reduce the downtime to fix those more major issues surfaced by health check issues.
