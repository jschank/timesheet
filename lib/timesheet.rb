require 'rubygems'
require 'fileutils'
require 'richunits'
require 'pathname'
require 'yaml'
require 'yaml/store'
require 'timesheet/range_extensions'
require 'timesheet/time_entry'
require 'timesheet/report_item'
require 'timesheet/time_log'
require 'timesheet/time_report'
require 'timesheet/trollop'
require 'timesheet/timesheet_parser'
require "timesheet/version"

module Timesheet
  class Timesheet

    def self.run(params)
      command_hash = {}
      command_hash = TimesheetParser.parse(params)

      raise "Cannot determine location for data. Try timesheet --help for details." unless (ENV["TIMESHEET_DATA_FILE"] || ENV["HOME"])

      data_file ||= ENV["TIMESHEET_DATA_FILE"]
      data_file ||= (ENV["HOME"] + "/.timesheet/store.yaml")

      FileUtils.makedirs(File.dirname(data_file))

      store = YAML::Store.new(data_file)
      tl = TimeLog.new(store)
      ts = Timesheet.new(tl)
      ts.process(command_hash)

    rescue Exception => e
      raise if command_hash[:debug]
      puts e.message

    end

    def initialize(timelog)
      @timelog = timelog
    end

    def process(command_opts)
      command = command_opts[:command]
      case command
        when :add    then process_add_command(command_opts)
        when :edit   then process_edit_command(command_opts)
        when :delete then process_delete_command(command_opts)
        when :report then process_report_command(command_opts)
        else raise "Unknown command #{command}"
      end
    end

    def process_add_command(command_opts)
      te = TimeEntry.new(command_opts[:project], command_opts[:start], command_opts[:end], command_opts[:comment])
      @timelog.add(te)
    end

    def process_edit_command(command_opts)
      record_number = command_opts.delete(:record_number)
      @timelog.update(record_number, command_opts)
      entries = [@timelog.find(record_number)]
      time_report = TimeReport.new(entries)
      time_report.report({:dump => true})
    end

    def process_delete_command(command_opts)
      record_number = command_opts.delete(:record_number)
      @timelog.delete(record_number)
    end

    def process_report_command(command_opts)
      start_time = command_opts[:start]
      end_time = command_opts[:end]
      entries = @timelog.extract_entries(start_time, end_time)
      time_report = TimeReport.new(entries)
      time_report.report(command_opts)
    end

  end
end
