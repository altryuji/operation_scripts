# -*- coding: utf-8 -*-

module OperationScriptsCommon
  class Confirmation
    def initialize(in_ = STDIN, out_ = STDOUT)
      @input  = in_
      @output = out_
    end

    def ask(question)
      question << " (y/n) " unless question.end_with?(" (y/n) ")
      @output.print question
      response = yes_or_no?(@input.gets.chomp)
      response.nil? ? ask(question) : response
    end

    def yes_or_no?(response)
      case response
      when "y" then true
      when "n" then false
      end
    end
  end

  def continue?
    Confirmation.new.ask "\nDo you continue?"
  end

  def continue_or_abort
    abort_with_message unless continue?
  end



  def start_msg(cmd)
    puts "\n[INFO ] #{Time.now}  The following command is going to be executed:\n $ #{cmd}\n"
  end

  def abort_with_message
    abort "\n[INFO ] #{Time.now}  The operation has stopped\n"
  end



  def exec_command(begin_confirmation = false, after_confirmation = begin_confirmation)
    continue_or_abort if begin_confirmation
    success = system yield
    if success
      continue_or_abort if after_confirmation
    else
      puts "\n[WARN ] #{Time.now}  Return code is not 0\n"
      continue_or_abort if after_confirmation
      raise
    end
  end

  def substitute_vars!(line, sub_pairs)
    sub_pairs.each { |before, after| line.gsub!(before, after) }
  end

  WITH_CONFIRMATION = '# with_confirmation'
  SECS_INCREMENTED_TILL_RETRY = 300
  def exec_command_file(file, substituted_pairs, dryrun = false, expected_retry_count = 0)
    File.open(file) do |f|
      f.each do |line|
        next if line =~ /^\s*#/
        next if line =~ /^\s*$/
        line.chomp!
        need_confirmation = line.end_with? WITH_CONFIRMATION
        command = line.gsub(WITH_CONFIRMATION, '')
        substitute_vars! command, substituted_pairs
        actual_retry_count = 0

        begin
          start_msg command unless command =~ /^\s*echo/
          dryrun ? (puts command) : (exec_command(need_confirmation) { command })
        rescue
          if expected_retry_count > actual_retry_count
            secs_till_retry ||= 0
            secs_till_retry += SECS_INCREMENTED_TILL_RETRY
            puts "I'm going to retry #{secs_till_retry.to_s} seconds later\n\n"
            sleep secs_till_retry
            actual_retry_count += 1
            retry
          end
        end
      end
    end
  end



  RE_SQL_COMMENT       ||= /^\s--.*$/
  RE_PROMPT_FOR_EXPECT ||= /.*=>/
  TIMEOUT_FOR_EXPECT   ||= 10
  def exec_command_file_using_expect(heroku_app, command_file, substituted_pairs, expect_verbose = false)
    $expect_verbose = expect_verbose

    PTY.spawn(start_psql(heroku_app)) do |r, w|
      w.sync = true

      File.open(command_file) do |f|
        f.each do |line|
          next if line =~ /^\s*#/
          next if line =~ /^\s*$/
          next if line =~ RE_SQL_COMMENT
          substitute_vars! line, substituted_pairs

          r.expect(RE_PROMPT_FOR_EXPECT, TIMEOUT_FOR_EXPECT) { w.puts line }
        end
      end
    end
  end

  def summarize_sql_logs(log_dir, heroku_app)
    Dir.chdir(log_dir) do
      Dir.glob("pgstats_*.log.#{heroku_app}.*").sort.each do |pgstats_tmp_filename|
        if /(?<log_filename>pgstats_.*\.log)\.(?<heroku_app>.*?)\.(?<datetime>\d{8}_\d{4})/ =~ pgstats_tmp_filename
          File.open("#{log_filename}.#{heroku_app}", 'a') do |f_a|
            File.open(pgstats_tmp_filename) do |f_r|
              f_r.each { |line| f_a << "#{datetime},#{line}" }
            end
          end
        end
        File.delete(pgstats_tmp_filename)
      end
    end
  end
end
