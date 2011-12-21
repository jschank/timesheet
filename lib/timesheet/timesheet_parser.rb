require 'time'
require 'chronic'
require 'richunits'

class TimesheetParser

  TIME_PERIODS = [:today, :current_week, :current_month, :yesterday, :last_week, :last_month]
  SUB_COMMANDS = %w(add list edit delete report)
  WEEK_START = "monday"
  USAGE = <<-EOS
  Timesheet is a script for keeping track of time spent on various projects.

  Usage:

  timesheet [OPTIONS] COMMAND [ARGS]

  COMMAND is any of the following:
    add
    edit
    delete
    list
    report

  see 'timesheet COMMAND --help' for more information on a specific command.

  Note: your timesheet data will be stored in a hidden directory under your user account. Timesheet
  figures out where this is by referencing the "HOME" environment variable. The default location is
  therefore: /Users/someuser/.timesheet/store.yaml

  You may override this location to any specific location you want by setting the "TIMESHEET_DATA_FILE"
  environment variable. This should be the full path to where you want the data stored. Including filename
  and extension. You only need to set this if you are unsatisfied with the default location.

  OPTIONS are:

  EOS

  def self.parse(args, outstream=STDOUT)

    global_opts = Trollop::options(args) do
      version "Timesheet #{Timesheet::VERSION} (c) 2009 John F. Schank III"
      banner USAGE
      stop_on SUB_COMMANDS

      opt :debug, "Show debugging information while processing"
    end

    if (args.nil? || args.empty?)
      Trollop::die "No parameters on command-line, use -h for help"
    end

    command = args.shift
    command_opts = case command
      when "add"
        add_options = Trollop::options(args) do
          banner <<-EOS
  timesheet add [OPTIONS]

      Adds an entry to the database.
      If there is an overlap, it should present a choice to split the entry, or abort.

  OPTIONS are:

EOS
          opt :project, "Project name", {:type => :string, :required => true}
          opt :start, "Start date-time", {:type => :time, :required => true}
          opt :end, "End date-time", {:type => :time, :required => true}
          opt :comment, "comment", {:type => :string}
          depends :start, :end
        end
        add_options[:command] = :add
        add_options

      when "edit"
        edit_options = Trollop::options(args) do
          banner <<-EOS
  timesheet edit [OPTIONS]

      Allows editing of existing entries

      Special Case: When the edit is done, the entire entry is displayed.
                    You can invoke an edit without changing anything 
                    to see a dump of a particular record.

  OPTIONS are:

EOS
          opt :record_number, "Record Number", {:type => :int, :required => true}
          opt :project, "Project name", {:type => :string}
          opt :start, "Start date-time", {:type => :time}
          opt :end, "End date-time", {:type => :time}
          opt :comment, "comment", {:type => :string}
        end

        edit_options[:command] = :edit
        edit_options

      when "delete"
        delete_options = Trollop::options(args) do
          banner <<-EOS
  timesheet delete [OPTIONS]

      Allows deletion of existing entries

  OPTIONS are:


EOS
          opt :record_number, "Record Number", {:type => :int, :required => true}
        end

        delete_options[:command] = :delete
        delete_options

      when "list"
        list_options = Trollop::options(args) do
          banner <<-EOS
  timesheet list [OPTIONS]

      Prints all matching entries. Any entry where the given date is covered by the entry.
      Each entry's record number is displayed

  OPTIONS are:


EOS
          opt :today, "Current Day"
          opt :current_week, "Current Week"
          opt :current_month, "Current Month"
          opt :yesterday, "Yesterday"
          opt :last_week, "Last Week"
          opt :last_month, "Last Month"
          opt :start, "Start date-time", {:type => :time}
          opt :end, "End date-time", {:type => :time}
          depends :start, :end
          conflicts :today, :current_week, :current_month, :yesterday, :last_week, :last_month, :start
        end

        # a list is just a detailed report.
        list_options[:command] = :report
        list_options[:detail] = true
        TIME_PERIODS.each do |period|
          list_options.merge!(convert_to_start_end(period)) if list_options[period]
          list_options.delete(period)
        end
        list_options.merge!(convert_to_start_end(:today)) unless list_options[:start]  # add default period
        list_options

      when "report"
        report_options = Trollop::options(args) do
          banner <<-EOS
  timesheet report [OPTIONS]

     displays total hours by project. For entries in the period.

     summary report shows hours spent on top level projects, and excludes comments
     detail shows hours for each item.
     byday shows hours for each day, with entries and comments. (daily breakout)

     defaults: --summary, and --today 

  OPTIONS are:


EOS
          opt :summary, "Summary report"
          opt :detail, "Detailed report"
          opt :byday, "By Day report"
          opt :today, "Current Day"
          opt :current_week, "Current Week"
          opt :current_month, "Current Month"
          opt :yesterday, "Yesterday"
          opt :last_week, "Last Week"
          opt :last_month, "Last Month"
          opt :start, "Start date-time", {:type => :time}
          opt :end, "End date-time", {:type => :time}
          conflicts :summary, :detail, :byday
          conflicts :today, :current_week, :current_month, :yesterday, :last_week, :last_month, :start
          depends :start, :end
        end
        report_options[:command] = :report
        TIME_PERIODS.each do |period|
          report_options.merge!(convert_to_start_end(period)) if report_options[period]
          report_options.delete(period)
        end
        report_options.merge!(convert_to_start_end(:today)) unless report_options[:start]  # add default period
        report_options.merge!({:summary => true}) unless report_options[:summary] || report_options[:detail] || report_options[:byday]
        report_options

      else
        Trollop::die "unknown subcommand #{command.inspect}"
    end

    opts = {}
    opts.merge! global_opts
    opts.merge! command_opts
    opts.merge!({:remainder => args})

    if (opts[:debug] )
      outstream.puts "Command-line options hash..."
      outstream.puts opts.inspect
    end

    raise ArgumentError.new("Command was not fully understood. Use --debug flag to diagnose.") unless opts[:remainder].empty?

    opts

  end

  def self.convert_to_start_end(period)
    periods = {}
    case period
      when :today
        periods[:start] = Chronic.parse('today at 12 am')
        periods[:end] = periods[:start] + 1.day

      when :current_week
        periods[:start] = Chronic.parse("this week #{WEEK_START} at 12 am")
        periods[:end] = periods[:start] + 1.week

      when :current_month
        today = Date.today
        next_month = today >> 1
        periods[:start] = Time.local(today.year, today.month, 1, 0, 0, 0)
        periods[:end] = Time.local(next_month.year, next_month.month, 1, 0, 0, 0)

      when :yesterday
        periods[:start] = Chronic.parse('yesterday at 12 am')
        periods[:end] = periods[:start] + 1.day

      when :last_week
        periods[:start] = Chronic.parse("this week #{WEEK_START} at 12 am") - 1.week
        periods[:end] = periods[:start] + 1.week

      when :last_month
        today = Date.today
        last_month = today << 1
        periods[:start] = Time.local(last_month.year, last_month.month, 1, 0, 0, 0)
        periods[:end] = Time.local(today.year, today.month, 1, 0, 0, 0)

      else raise "Unknown time period #{period.to_s}"
    end
    periods
  end

end