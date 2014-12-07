require 'active_support/all'

module LogHelper
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
      extend ClassMethods
    end
  end

  module InstanceMethods
    def search_latest_log(re_filename)
      search_log_using_timestamp_in_filename(re_filename, -1)
    end
    def search_second_latest_log(re_filename)
      search_log_using_timestamp_in_filename(re_filename, -2)
    end

    def search_log_using_timestamp_in_filename(re_filename, index)
      log = Dir.glob('*').grep(re_filename).sort[index]
      log.present? ? log : nil
    end

    def any_logfile_exist?
      latest_log ? true : false
    end
  end



  module ClassMethods
    def already_read?(log_filename)
      raise "#{log_filename} doesn't exist" unless File.exists?(log_filename)

      if File.exists? filepointer_filename(log_filename)
        true
      else
        false
      end
    end

    def count_message(filename, message_condition)
      filepointer = read_filepointer(filename)

      message_count = 0
      File.open(filename, 'r') do |f|
        f.seek(filepointer, IO::SEEK_SET)
        f.each do |line|
          begin
            if /#{message_condition}/ =~ line
              message_count += 1
            end
          rescue ArgumentError => e
            # ignore exception as it's just reading log file
          rescue Exception => e
            # ignore exception as it's just reading log file
          end
        end

        write_filepointer(filename, f.pos)
      end

      message_count
    end


  private
    #################### filepointer
    def filepointer_filename(log_filename)
      "#{File.basename(log_filename)}.fp"
    end

    def initialize_filepointer_file(log_filename)
      fp_filename = filepointer_filename(log_filename)
      File.open(fp_filename, 'w') { |f| f << 0 }
    end

    def read_filepointer(log_filename)
      fp_filename = filepointer_filename(log_filename)
      unless File.exists? fp_filename
        initialize_filepointer_file(log_filename)
      end

      File.read(fp_filename).to_i
    end

    def write_filepointer(log_filename, file_pointer)
      fp_filename = filepointer_filename(log_filename)
      File.open(fp_filename, 'w') { |f| f << file_pointer.to_i }
    end
    #################### filepointer
  end
end
