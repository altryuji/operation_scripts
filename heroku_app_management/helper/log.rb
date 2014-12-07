require_relative '../../helper/log_helper'

module HerokuAppManagement
  module Log
    include LogHelper

    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
      end
    end

    module InstanceMethods
      def re_log_filename
        /^#{@app_name}_\d{8}.log$/
      end

      def latest_log
        @latest_log ||= search_latest_log(re_log_filename)
      end

      def second_latest_log
        @second_latest_log ||= search_second_latest_log(re_log_filename)
      end
    end
  end
end
