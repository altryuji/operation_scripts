require_relative 'helper/dyno'
require_relative 'helper/addon'
require_relative 'helper/log'
require_relative './config'

module HerokuAppManagement
  class HerokuApp
    include Dyno
    include Addon
    include Log

    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end

    APP_NAME_SEPARATOR = '-'
    def app_name_prefix_for_dev(separater = APP_NAME_SEPARATOR)
      prefix = @app_name.split(separater)[0]
      if prefix.start_with? 'store'
        raise "#{@app_name} is not an app for the development environment, but for the production environment."
      end

      prefix
    end
  end
end
