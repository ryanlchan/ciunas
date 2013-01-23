module Ciunas
  class Logger < Rails::Rack::Logger
    def initialize(*args)
      @opts ||= {}
      # Silenced paths will be totally silenced using logger#silence
      @opts[:silenced] =  if args.last.is_a?(Hash) && args.last[:silenced]
                            args.last[:silenced]
                          elsif ENV['SILENCED_PATHS']
                            case ENV['SILENCED_PATHS']
                            when String
                              ENV['SILENCED_PATHS'].split(" ")
                            when Array
                              ENV['SILENCED_PATHS']
                            end
                          end
      @opts[:silenced] = [] unless @opts[:silenced].is_a?(Array)

      # Muted paths will be muted to ERROR messages
      @opts[:muted] =  if args.last.is_a?(Hash) && args.last[:muted]
                            args.last[:muted]
                          elsif ENV['MUTED_PATHS']
                            case ENV['MUTED_PATHS']
                            when String
                              ENV['MUTED_PATHS'].split(" ")
                            when Array
                              ENV['MUTED_PATHS']
                            end
                          end
      @opts[:muted] = [] unless @opts[:muted].is_a?(Array)

      super(*(args.first(2))) # Reuse Rails::Rack::Logger's initializer, which uses only two config args
    end

    def call(env)
      if env['X-SILENCE-LOGGER'] || @opts[:silenced].any? {|m| m === env['PATH_INFO'] }
        Rails.logger.silence do
          @app.call(env)
        end
      elsif env['X-MUTE-LOGGER'] || @opts[:muted].any? {|m| m === env['PATH_INFO'] }
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
