module HerokuAppManagement
  module Addon
    module Database
      PRICE_FOR_LEGACY_PLAN = { 'Premium Mecha'   => 6000,
                                'Premium Baku'    => 3500,
                                'Mecha'           => 3500,
                                'Standard Mecha'  => 3500,
                                'Standard Baku'   => 2000,
                                'Baku'            => 2000,
                                'Zilla'           => 1600,
                                'Premium Ika'     => 1200,
                                'Standard Ika'    => 750,
                                'Ika'             => 750,
                                'Fugu'            => 400,
                                'Premium Tengu'   => 350,
                                'Premium Tengu'   => 200,
                                'Premium Yanari'  => 200,
                                'Standard Tengu'  => 200,
                                'Ronin'           => 200,
                                'Kappa'           => 100,
                                'Standard Yanari' => 50,
                                'Crane'           => 50,
                                'Basic'           => 9,
                                'Dev'             => 0,
                              }

      PRICE_FOR_CURRENT_PLAN = { 'Premium 7'    => 6000,
                                 'Standard 7'   => 3500,
                                 'Premium 6'    => 3500,
                                 'Standard 6'   => 2000,
                                 'Premium 4'    => 1200,
                                 'Standard 4'   => 750,
                                 'Premium 2'    => 350,
                                 'Standard 2'   => 200,
                                 'Premium 0'    => 200,
                                 'Standard 0'   => 50,
                                 'Hobby-basic'  => 9,
                                 'Hobby basic'  => 9,
                                 'Hobby-dev'    => 0,
                                 'Hobby dev'    => 0,
                               }

      PRICE = PRICE_FOR_CURRENT_PLAN.merge PRICE_FOR_LEGACY_PLAN
    end


    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
      end
    end

    module InstanceMethods
      #################### database
      def database_plan
        @database_plan ||= `heroku pg:info -a #{@app_name} | egrep 'Plan' | awk -F':' '{print $2}'`.strip
      end

      def expected_database_plan
        app = YAML.load(File.read(ADDON_DEFINITION_YAML))[@app_name]
        return app['database'] if app

        { 'dev'      => 'Basic',
          'staging'  => 'Basic',
          'clone'    => 'Dev',
          'rollback' => 'Dev',
        }[app_name_prefix_for_dev]
      end

      def database_plans_proper?
        return false if database_plan.blank?

        cost_of_expected_database_plan = Database::PRICE[expected_database_plan]
        cost_of_database_plan          = Database::PRICE[database_plan]

        if cost_of_database_plan <= cost_of_expected_database_plan
          true
        else
          false
        end
      end
      #################### database
    end
  end
end
