#!/usr/bin/env ruby

require 'optparse'
require 'pty'
require 'expect'
require_relative '../operation_scripts_common'
include ::OperationScriptsCommon

DEFAULT_SQL_FILE = __FILE__.sub(/\.rb\Z/, '.sql')

def parse_args(argv = ARGV)
  opts      = {}
  opt_helps = { a: '(required) heroku application you want to connect',
                f: "(optional) file which contains sql(s) (default #{DEFAULT_SQL_FILE}.sql)",
              }

  argv.options do |opt|
    # default settings
    opts[:sql_file] = DEFAULT_SQL_FILE

    opt.on('-a HEROKU_APP', opt_helps[:a]) { |v| opts[:heroku_app] = v }
    opt.on('-f SQL_FILE',   opt_helps[:f]) { |v| opts[:sql_file]   = v }

    opt.parse! rescue abort " ERROR: Invalid option.\n\n #{opt}"
    abort " ERROR: Invalid option.\n\n #{opt}" if opts[:heroku_app].nil?
  end

  opts
end

def start_psql(heroku_app)
  "heroku pg:psql -a #{heroku_app}"
end


OPTS = parse_args
heroku_app = OPTS[:heroku_app]
exec_command_file_using_expect(heroku_app, OPTS[:sql_file], {})
