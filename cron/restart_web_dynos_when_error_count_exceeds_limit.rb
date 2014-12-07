#!/usr/bin/env ruby

require 'optparse'
require 'active_support/all'
require_relative 'send_mail'
require_relative '../heroku_app_management/heroku_app'
require_relative '../helper/log_helper'
include ::HerokuAppManagement

def parse_args(argv = ARGV)
  opts      = {}
  opt_helps = { a: '(required) heroku application you want to connect',
                f: '(required) from address for sending mail',
                p: '(required) password for sending mail',
                t: '(required) to addresses for sending email (e.g., "hoge, foo")',
                l: '(optional) log directory in which log files exist (e,g., /var/logging)',
                i: '(optional) interval to restart app (secs) (default: 10 minutes)',
                s: '(optional) threashold of number of error message at given time interval to restart (default: 100)',
              }

  argv.options do |opt|
    opts[:log_dir]   = '/var/logging'
    opts[:interval]  = 10.minutes
    opts[:threshold] = 100

    opt.on('-a HEROKU_APP',   opt_helps[:a]) { |v| opts[:heroku_app]   = v }
    opt.on('-f FROM_ADDRESS', opt_helps[:f]) { |v| opts[:from_address] = v }
    opt.on('-p PASSWORD',     opt_helps[:p]) { |v| opts[:password]     = v }
    opt.on('-t TO_ADDRESSES', opt_helps[:t]) { |v| opts[:to_addresses] = v }
    opt.on('-l LOG_DIR',      opt_helps[:l]) { |v| opts[:log_dir]      = v }
    opt.on('-i INTERVAL',     opt_helps[:i]) { |v| opts[:interval]     = v.to_i }
    opt.on('-s THRESHOLD',    opt_helps[:s]) { |v| opts[:threshold]    = v.to_i }

    opt.parse! rescue abort " ERROR: Invalid option.\n\n #{opt}"
    abort " ERROR: Invalid option.\n\n #{opt}" if opts.values_at(:heroku_app, :from_address, :password, :to_addresses).any?(&:nil?)
  end

  opts
end

def notify_restart(error_count)
  subject = "[Alert] #{APP_NAME} was restarted"
  body    = "number of error message (#{ERROR_MESSAGE}): #{error_count}"
  send_mail(USER, PASS, FROM_ADDR, TO_ADDRS, subject, body)
end

def write_number_of_messages(count, message)
  File.open(SCRIPT_LOG, 'a') { |f| f << "#{NOW.iso8601} #{count} (#{message})\n" }
end

def write_restart_timestamp(timestamp = NOW.iso8601)
  File.open(RESTART_LOG, 'a') { |f| f << "#{timestamp}\n" }
end

def interval_between_now_and_last_restart
  t_last_restart = Time.parse(last_restart_timestamp)
  NOW - t_last_restart
end

def last_restart_timestamp
  # If there is no restarg_log, write Time.at(0) to the log file.
  # Therefore, if the error message count is exceeded for the first time the script is run,
  # the dynos are restarted.
  unless File.exists? RESTART_LOG
    write_restart_timestamp(Time.at(0).iso8601)
  end
  File.open(RESTART_LOG, 'r').readlines.last.split[0]
end


OPTS                       = parse_args
APP_NAME                   = OPTS[:heroku_app]
INTERVAL_SECS_TO_RESTART   = OPTS[:interval]
THRESHOLD_OF_ERROR_MESSAGE = OPTS[:threshold]

FROM_ADDR = OPTS[:from_address]
TO_ADDRS  = OPTS[:to_addresses].split(',').map(&:strip)
USER      = FROM_ADDR
PASS      = OPTS[:password]

ERROR_MESSAGE = 'Request timeout'
SCRIPT_LOG    = "#{APP_NAME}_#{File.basename(__FILE__, '.*')}.log"
RESTART_LOG   = "#{APP_NAME}_restart.log"
NOW           = Time.now


Dir.chdir(OPTS[:log_dir]) do
  app = HerokuApp.new(APP_NAME)
  abort "There is no log files for #{APP_NAME}." unless app.any_logfile_exist?

  error_count = 0
  if !Log.already_read?(app.latest_log) && app.second_latest_log
    error_count = Log.count_message(app.second_latest_log, ERROR_MESSAGE)
  end
  error_count += Log.count_message(app.latest_log, ERROR_MESSAGE)

  if error_count >= THRESHOLD_OF_ERROR_MESSAGE
    # TODO: retrieve some system information here for more investigation

    if interval_between_now_and_last_restart >= INTERVAL_SECS_TO_RESTART
      app.restart_web_dynos
      write_restart_timestamp
      notify_restart(error_count)
    end
  end

  write_number_of_messages(error_count, ERROR_MESSAGE)
end
