module Ciunas
  class Logger < Rails::Rack::Logger
    def initialize(*args)
      @opts ||= {}
      @opts[:silenced] =  if args.last.is_a?(Hash) && args.last[:silenced]
                            args.last[:silenced]
                          elsif ENV['SILENCED_PATHS']
                            ENV['SILENCED_PATHS']
                          end
      @opts[:silenced] = [] unless @opts[:silenced].is_a?(Array)

      super(*(args.first(2))) # Reuse Rails::Rack::Logger's initializer, which uses only two config args
    end

    def call(env)
      if env['X-SILENCE-LOGGER'] || @opts[:silenced].any? {|m| m === env['PATH_INFO'] }
        begin
          # temporarily set the rails log level to error
          tmp_log_level = ActiveSupport::BufferedLogger::Severity::ERROR
          old_logger_level, Rails.logger.level = Rails.logger.level, tmp_log_level
          @app.call(env)
        ensure
          Rails.logger.level = old_logger_level
        end
      else
        super(env)
      end
    end
  end
end
