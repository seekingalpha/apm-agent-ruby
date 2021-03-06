# frozen_string_literal: true

require 'elastic_apm/subscriber'

module ElasticAPM
  # @api private
  class Railtie < Rails::Railtie
    config.elastic_apm = ActiveSupport::OrderedOptions.new

    Config::DEFAULTS.each { |option, value| config.elastic_apm[option] = value }

    initializer 'elastic_apm.initialize' do |app|
      config = app.config.elastic_apm.merge(app: app)

      begin
        agent = ElasticAPM.start config

        if agent
          agent.instrumenter.subscriber = ElasticAPM::Subscriber.new(agent)

          app.middleware.insert 0, Middleware
        end
      rescue StandardError => e
        Rails.logger.error "#{Log::PREFIX}Failed to start: #{e.message}"
        Rails.logger.debug e.backtrace.join("\n")
      end
    end

    config.after_initialize do
      require 'elastic_apm/spies/action_dispatch'
    end
  end
end
