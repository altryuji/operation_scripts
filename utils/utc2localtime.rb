#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Description:
#   Convert UTC to localtime.
#   (heroku logs are output in UTC timezone.)
#
# Usage:
#   ./utc2localtime.rb <file>
#
# Existing Problems:
#   The following error occurs.
#     ArgumentError invalid byte sequence in UTF-8
#

require 'time'

def utc2localtime(file)
  line_num  = 1
  lines_err = []

  File.open(file) do |f|
    f.each do |line|
      begin
        if /^(?<date>\d{4}-\d{2}-\d{2})T(?<time>\d{2}:\d{2}:\d{2}(\.\d{6})?)\+00:00\s(?<message>.+)$/ =~ line
          puts "#{Time.parse("#{date} #{time} UTC").localtime.iso8601} #{message}"
        end
      rescue Exception => e
        lines_err << "#{line_num}: #{e.class} #{e.message}"
      end
      line_num += 1
    end
  end

  unless lines_err.empty?
    puts "There are lines which could't be converted."
    puts lines_err.join("\n")
  end
end

while argv = ARGV.shift
  utc2localtime argv
end
