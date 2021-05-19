# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/custom_logger'
require 'logger'
require 'octokit'
require 'github_api'
require 'redis-sinatra'
require 'json'
require 'yaml'

KEYWORDS = [
  "faraday",
  "xray",
  "datadog",
  "splunk",
  "github",
  "zipkin",
  "cloudwatch",
  "alibaba",
  "azure"
]


# ---------------------------------------#
require 'opentelemetry/sdk'
require 'opentelemetry-instrumentation-rack'
require 'opentelemetry-instrumentation-sinatra'
require 'opentelemetry-instrumentation-faraday'
require 'opentelemetry-instrumentation-redis'
require 'opentelemetry-instrumentation-http'
require 'opentelemetry/exporter/jaeger'

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
# ---------------------------------------#

# # ---------------------------------------#
# require 'ddtrace'

# Datadog.configure do |c|
#   c.service = 'sandbox_test_ruby'
#   c.use :rack
#   c.use :sinatra, service_name: 'sandbox_test_ruby'
#   c.use :faraday
#   c.use :redis
#   c.use :http
# end
# # ---------------------------------------#

class Multivac < Sinatra::Base
  helpers Sinatra::CustomLogger
  # register Datadog::Contrib::Sinatra::Tracer

  configure do
    # set :client, Octokit::Client.new
    set :client, Github.new
    redis_config = YAML.load(File.open('redis.yml'))
    dflt = redis_config['default']
    set :cache, Sinatra::Cache::RedisStore.new(dflt)

    logger = Logger.new(STDOUT)
    logger.progname = 'multivac'
    original_formatter = Logger::Formatter.new
    # logger.formatter  = proc do |severity, datetime, progname, msg|
    #   # ---------------------------------------#
    #   current_span = OpenTelemetry::Trace.current_span(OpenTelemetry::Context.current).context
      
    #   dd_trace_id = current_span.trace_id.unpack1('H*')[16, 16].to_i(16).to_s
    #   dd_span_id = current_span.span_id.unpack1('H*').to_i(16).to_s
    #   # ---------------------------------------#

    #   # # ---------------------------------------#      
    #   # correlation = Datadog.tracer.active_correlation

    #   # dd_trace_id = correlation.trace_id.to_s,
    #   # dd_span_id = correlation.span_id.to_s
    #   # # ---------------------------------------#
      
    #   if dd_trace_id
    #     "#{{datetime: datetime, progname: progname, severity: severity, message: msg, 'dd.trace_id': dd_trace_id, 'dd.span_id': dd_span_id}.to_json}\n"
    #   else
    #     "#{{datetime: datetime, progname: progname, severity: severity, message: msg}.to_json}\n"
    #   end
    # end

    set :logger, logger
  end

  get '/' do
    'Hello World!'
  end

  get '/_health' do
    'Hello Heath!'
  end

  get '/search_open_issues' do
    begin
      logger.info('checking github for open issues')
      cached_open_issues = settings.cache.read('incorrect_cache')

      if cached_open_issues
        open_issues = JSON.parse(cached_open_issues)
      else
        do_not_cache = false
        open_issues = {}
        KEYWORDS.each do |keyword|
          open_issues[keyword] = {
            "issues" => {},
          }

          begin
            keyword_results = settings.client.search.issues("org:open-telemetry #{keyword}")
            open_issues[keyword]["triage_needed"] = keyword_results.total_count > 5 ? 'yes' : 'no'
            keyword_results.items.each do |item|
              item_attributes = item
              open_issues[keyword]["issues"][item_attributes[:number]] = {
                "title" => item_attributes[:title],
                "html_url" => item_attributes[:html_url]
              }
            end
          rescue Github::Error::GithubError

            do_not_cache = true
          end
        end

        settings.cache.write('open_issues', open_issues.to_json, expire_after: 10) if do_not_cache
      end

      erb :open_issues, locals: {
        data: open_issues
      }
    rescue StandardError => e
      logger.error("Error when making search_open_issues check: #{e.message} #{e.backtrace[0]}")

      status 500
    end
  end
end
