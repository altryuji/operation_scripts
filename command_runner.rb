#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require_relative './operation_scripts_common'
include ::OperationScriptsCommon

def parse_args(argv = ARGV)
  opts = {}
  opt_helps = { a: '(required) app name',
                v: '(required) tag version (e.g., 1.1.0)',
                c: '(required) command line file in shell format under command_templates directory that is going to be executed',
                t: '(optional) prefix for test environment e.g., clone, staging, rollback',
                T: '(optional) app name on test environment e.g., staging-app',
                m: '(optional) e.g., "heroku config:set XXX=YYY"',
                s: '(optional) maintenance start time',
                e: '(optional) maintenance end time',
                r: '(optional) retry when failed',
                u: '(optional) ssh user to step server for dev',
                h: '(optional) step server for dev',
                p: '(optional) path to source code',
                n: '(optional) dry run',
                f: '(optional) force push',
                d: '(optional) skip database backup',
                z: '(optional) execute analyze',
                D: '(optional) heroku-postgres database tier(default: heroku-postgresql:crane)',
                V: '(optional) heroku-postgres database version(default: 9.2)',
              }

  argv.options do |opt|
    test_envs = %w(clone staging rollback)

    # default settings
    opts[:test_env]                        = 'clone'
    opts[:mainte_start_time]               = '09:30'
    opts[:mainte_end_time]                 = '11:30'
    opts[:retry_count]                     = 0
    opts[:source_code_path]                = ''
    opts[:dryrun]                          = false
    opts[:force_push]                      = ''
    opts[:database_backup]                 = 'true'
    opts[:execute_analyze]                 = 'false'
    opts[:database_tier]                   = 'heroku-postgresql:crane'
    opts[:database_version]                = '9.2'

    opt.on('-a HEROKU_APP',                                                                opt_helps[:a]) { |v| opts[:heroku_app]                      = v }
    opt.on('-v VERSION',                                                                   opt_helps[:v]) { |v| opts[:version]                         = v }
    opt.on('-c FILE',                                                                      opt_helps[:c]) { |v| opts[:command_file]                    = v }
    opt.on('-t TEST_ENV (default: clone)',                                                 opt_helps[:t]) { |v| opts[:test_env]                        = v }
    opt.on('-T TEST_APP',                                                                  opt_helps[:T]) { |v| opts[:test_app]                        = v }
    opt.on('-m "COMMAND_TO_CHANGE_HEROKU_CONFIG"',                                         opt_helps[:m]) { |v| opts[:change_heroku_config]            = v }
    opt.on('-s HH:MM',                                                                     opt_helps[:s]) { |v| opts[:mainte_start_time]               = v }
    opt.on('-e HH:MM',                                                                     opt_helps[:e]) { |v| opts[:mainte_end_time]                 = v }
    opt.on('-r COUNT', '--retry-count=COUNT',                                              opt_helps[:r]) { |v| opts[:retry_count]                     = v.to_i }
    opt.on('-u SSH_USER_TO_STEP_SERVER_FOR_DEV', '--ssh-user-to-step-server-for-dev=USER', opt_helps[:u]) { |v| opts[:ssh_user_to_step_server_for_dev] = v }
    opt.on('-h STEP_SERVER_FOR_DEV', '--step-server-for-dev=HOST',                         opt_helps[:h]) { |v| opts[:step_server_for_dev]             = v }
    opt.on('-p SOURCE_CODE_PATH',                                                          opt_helps[:p]) { |v| opts[:source_code_path]                = v }
    opt.on('-n', '--dry-run',                                                              opt_helps[:n]) {     opts[:dryrun]                          = true }
    opt.on('-f', '--force-push',                                                           opt_helps[:f]) {     opts[:force_push]                      = '-f' }
    opt.on('-d', '--skip-database-backup',                                                 opt_helps[:d]) { |v| opts[:database_backup]                 = 'false' if v }
    opt.on('-z', '--execute-analyze',                                                      opt_helps[:z]) {     opts[:execute_analyze]                 = 'true' }
    opt.on('-D DATABASE_TIER', '--database-tier',                                          opt_helps[:D]) { |v| opts[:database_tier]                   = v}
    opt.on('-V DATABASE_VERSION', '--database-version',                                    opt_helps[:V]) { |v| opts[:database_version]                = v}

    opt.parse! rescue abort " ERROR: Invalid option.\n\n #{opt}"
    abort " ERROR: Invalid option.\n\n #{opt}" if opts.values_at(:heroku_app, :version, :command_file).any?(&:nil?)
    abort "\nThe argument of -t should be clone, staging or rollback\n\n" if !(opts[:test_env].nil?) && !(test_envs.include? opts[:test_env])
    abort " ERROR: Execute(source) the setup script first.\n\n" if !(ENV['SETUP_FOR_VERSION_UP'] == 'true') && (opts[:dryrun] == false)
  end
  opts[:test_app] ||= "#{opts[:test_env]}-#{opts[:heroku_app]}"

  opts
end

OPTS = parse_args
p OPTS
config_no_change_message = "echo 'No change in environment variables on production/test server.'"
substituted_pairs = {
  '${HEROKU_APP_ORIG}'                 => OPTS[:heroku_app],
  '${HEROKU_APP_TEST}'                 => OPTS[:test_app],
  '${HEROKU_APP_TEST_SHORT_NAME}'      => OPTS[:test_app].split('-')[0..1].join('-'),
  '${VERSION}'                         => OPTS[:version],
  '${CHANGE_HEROKU_CONFIG_TO_PROD}'    => (OPTS[:change_heroku_config] ? "#{OPTS[:change_heroku_config]} --app #{OPTS[:heroku_app]}"                    : config_no_change_message),
  '${CHANGE_HEROKU_CONFIG_TO_TEST}'    => (OPTS[:change_heroku_config] ? "#{OPTS[:change_heroku_config]} --app #{OPTS[:test_env]}-#{OPTS[:heroku_app]}" : config_no_change_message),
  '${TODAY}'                           => Time.now.strftime('%Y%m%d'),
  '${MAINTENANCE_DATE}'                => Time.now.strftime('%Y/%m/%d'),
  '${MAINTENANCE_START_TIME}'          => OPTS[:mainte_start_time],
  '${MAINTENANCE_END_TIME}'            => OPTS[:mainte_end_time],
  '${SSH_USER_TO_STEP_SERVER_FOR_DEV}' => OPTS[:ssh_user_to_step_server_for_dev],
  '${STEP_SERVER_FOR_DEV}'             => OPTS[:step_server_for_dev],
  '${SOURCE_CODE_PATH}'                => OPTS[:source_code_path],
  '${FORCE_PUSH}'                      => OPTS[:force_push],
  '${DATABASE_BACKUP}'                 => OPTS[:database_backup],
  '${EXECUTE_ANALYZE}'                 => OPTS[:execute_analyze],
  '${DATABASE_TIER}'                   => OPTS[:database_tier],
  '${DATABASE_VERSION}'                => OPTS[:database_version],
}

exec_command_file OPTS[:command_file], substituted_pairs, OPTS[:dryrun], OPTS[:retry_count]
