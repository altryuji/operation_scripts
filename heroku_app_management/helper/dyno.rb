module HerokuAppManagement
  module Dyno
    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
      end
    end

    module InstanceMethods
      #################### restart
      def restart_app
        system("heroku restart -a #{@app_name}")
      end

      def restart_web_dynos
        restart_dynos('web')
      end

      def restart_worker_dynos
        restart_dynos('worker')
      end

      def restart_dynos(dyno_type)
        send("#{dyno_type}_dynos").each { |dyno| system("heroku restart #{dyno} -a #{@app_name}") }
      end
      private :restart_dynos
      #################### restart

      #################### dyno
      def dynos
        dyno_types_pattern = "^web|^worker"
        @dynos ||= `heroku ps -a "#{@app_name}" | egrep "#{dyno_types_pattern}" | awk -F: '{print $1}'`.split
      end

      def web_dynos
        dynos.select { |d| d.start_with?("web") }
      end

      def worker_dynos
        dynos.select { |d| d.start_with?("worker") }
      end

      def numbers_of_each_type_of_dyno
        [web_dynos.size, worker_dynos.size]
      end

      def expected_numbers_of_each_type_of_dyno
        app = YAML.load(File.read(DYNO_DEFINITION_YAML))[@app_name]
        return app['dyno'] if app

        #         web dyno, worker dyno
        { 'dev'      => [1, 0],
          'staging'  => [1, 0],
          'clone'    => [1, 0],
          'rollback' => [1, 0],
        }[app_name_prefix_for_dev]
      end

      def numbers_of_each_type_of_dynos_proper?
        actual_web_dyno,   actual_worker_dyno   = numbers_of_each_type_of_dyno
        expected_web_dyno, expected_worker_dyno = expected_numbers_of_each_type_of_dyno

        if (expected_web_dyno >= actual_web_dyno) && (expected_worker_dyno >= actual_worker_dyno)
          true
        else
          false
        end
      end
      #################### dyno
    end
  end
end
