#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pty'
require 'expect'
require_relative '../operation_scripts_common'
include ::OperationScriptsCommon

def parse_args(argv = ARGV)
  opts      = {}
  opt_helps = { a: '(required) heroku application you want to connect',
                d: '(optional) log directory in which output of sql is put (e,g., /var)',
                f: '(optional) file which contains sql(s) (e.g., hoge.sql)',
                v: '(optional) set $expect_verbose true (defaults to false)',
              }

  argv.options do |opt|
    # default settings
    opts[:log_dir]  = '/var/pgstats'
    opts[:sql_file] = __FILE__.sub(/\.rb\Z/, '.sql')

    opt.on('-a HEROKU_APP', opt_helps[:a]) { |v| opts[:heroku_app]     = v }
    opt.on('-d LOG_DIR',    opt_helps[:d]) { |v| opts[:log_dir]        = v }
    opt.on('-f SQL_FILE',   opt_helps[:f]) { |v| opts[:sql_file]       = v }
    opt.on('-v',            opt_helps[:v]) { |v| opts[:expect_verbose] = true }

    opt.parse! rescue abort " ERROR: Invalid option.\n\n #{opt}"
    abort " ERROR: Invalid option.\n\n #{opt}" if opts[:heroku_app].nil?
  end

  opts
end

def start_psql(heroku_app)
  "heroku pg:psql -a #{heroku_app}"
end


OPTS              = parse_args
heroku_app        = OPTS[:heroku_app]
substituted_pairs = {
  '${TIMESTAMP}'  => Time.now.strftime('%Y%m%d_%H%M'),
  '${DBNAME}'     => `heroku pg:credentials DATABASE --app #{heroku_app} | grep "dbname=" | awk '{print $1}' | sed -e 's/"dbname=//'`.chomp,
  '${HEROKU_APP}' => heroku_app,
  '${LOG_DIR}'    => OPTS[:log_dir],
}

exec_command_file_using_expect(heroku_app, OPTS[:sql_file], substituted_pairs, OPTS[:expect_verbose])
summarize_sql_logs(OPTS[:log_dir], heroku_app)
