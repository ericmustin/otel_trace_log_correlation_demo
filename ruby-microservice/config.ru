# frozen_string_literal: true

# config.ru
require 'opentelemetry/sdk'
require 'opentelemetry-instrumentation-rack'
require 'opentelemetry-instrumentation-sinatra'
require 'opentelemetry-instrumentation-faraday'
require 'opentelemetry-instrumentation-redis'
require 'opentelemetry-instrumentation-http'
require 'opentelemetry/exporter/jaeger'

require 'rack/protection'
require './app'

OpenTelemetry::SDK.configure do |c|
  c.service_name = "sandbox_test_ruby"
  c.use 'OpenTelemetry::Instrumentation::Rack'
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.use 'OpenTelemetry::Instrumentation::Faraday'
  c.use 'OpenTelemetry::Instrumentation::Redis'
  c.use 'OpenTelemetry::Instrumentation::HTTP'

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      # for the jaeger exporter:
      OpenTelemetry::Exporter::Jaeger::CollectorExporter.new()
    )
  )
end

run Multivac
