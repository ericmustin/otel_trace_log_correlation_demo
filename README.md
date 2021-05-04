## OpenTelemetry Datadog Sandbox

This Repository allows users to deploy a sandbox distributed tracing application instrumented with OpenTelemetry SDKs, which emit traces to OpenTelemetry Collectors, and export Telemetry data to Datadog via the Datadog Exporter. It also demonstrates how to manually inject datadog formatted trace and span ids in an Application instrumented with OpenTelemetry SDKs in Ruby, Python, and Node.

To learn more about OpenTelemetry, please review the [Datadog Documentation](https://docs.datadoghq.com/tracing/setup_overview/open_standards/#opentelemetry-collector-datadog-exporter)

### Docker-Compose

This test environment is useful for testing Docker-specific behavior of the exporter.
It defines a standalone collector setup within a docker network, and generates traffic at a rate of 1 request per second for 15 minutes.

1. Replace <YOUR_API_KEY> with your API key in `otel-collector-config.yml`
  - If you also wish to enable log collection, Replace <YOUR_API_KEY> with your API key in `fluent-bit/fluent-bit.conf`
2. `$ docker-compose build`
3. `$ docker-compose up`
4. make a few requests to `localhost:3000/search_open_issues` to see examples of a successful response, an error response, and trace / log correlation within the Datadog UI.
