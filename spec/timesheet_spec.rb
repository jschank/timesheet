require File.dirname(__FILE__) + '/spec_helper.rb'

describe Timesheet do

  context "when being invoked" do

    it "should print an error when no environment values are defined" do

      params = mock("ARGV")
      command_hash = mock("command_hash")

      TimesheetParser.should_receive(:parse).with(params).once.and_return(command_hash)

      ENV.should_receive(:[]).with("TIMESHEET_DATA_FILE").once.and_return(nil)
      ENV.should_receive(:[]).with("HOME").once.and_return(nil)

      command_hash.should_receive(:[]).with(:debug).once.and_return(nil)

      Timesheet::Timesheet.should_receive(:puts).with("Cannot determine location for data. Try timesheet --help for details.").once.and_return(nil)

      Timesheet::Timesheet.run(params)

    end

    it "should use the environment value for TIMESHEET_DATA_FILE if it is defined" do

      params = mock("ARGV")
      command_hash = mock("command_hash")
      store = mock("store")
      time_log = mock("time_log")
      time_sheet = mock("time_sheet")
      timesheet_data_file = mock('ENV["TIMESHEET_DATA_FILE"]')

      expected_timesheet_data_file = "/somepath/someotherpath/somefile.someext"
      expected_timesheet_data_file_path = "/somepath/someotherpath"

      TimesheetParser.should_receive(:parse).with(params).once.and_return(command_hash)

      ENV.should_receive(:[]).with("TIMESHEET_DATA_FILE").twice.and_return(expected_timesheet_data_file)

      File.should_receive(:dirname).with(expected_timesheet_data_file).once.and_return(expected_timesheet_data_file_path)
      FileUtils.should_receive(:makedirs).with(expected_timesheet_data_file_path).once.and_return(expected_timesheet_data_file_path)

      YAML::Store.should_receive(:new).with(expected_timesheet_data_file).once.and_return(store)
      TimeLog.should_receive(:new).with(store).once.and_return(time_log)
      Timesheet::Timesheet.should_receive(:new).with(time_log).once.and_return(time_sheet)
      time_sheet.should_receive(:process).with(command_hash)

      Timesheet::Timesheet.run(params)

    end

    it "should use the environment value for HOME if it is defined and TIMESHEET_DATA_FILE is not" do

      params = mock("ARGV")
      command_hash = mock("command_hash")
      store = mock("store")
      time_log = mock("time_log")
      time_sheet = mock("time_sheet")

      expected_home = "/Users/someuser"
      expected_data_file = "/Users/someuser/.timesheet/store.yaml"
      expected_data_file_path = "/Users/someuser/.timesheet"

      TimesheetParser.should_receive(:parse).with(params).once.and_return(command_hash)

      ENV.should_receive(:[]).with("TIMESHEET_DATA_FILE").twice.and_return(nil)
      ENV.should_receive(:[]).with("HOME").twice.and_return(expected_home)

      File.should_receive(:dirname).with(expected_data_file).once.and_return(expected_data_file_path)
      FileUtils.should_receive(:makedirs).with(expected_data_file_path).once.and_return(expected_data_file_path)

      YAML::Store.should_receive(:new).with(expected_data_file).once.and_return(store)
      TimeLog.should_receive(:new).with(store).once.and_return(time_log)
      Timesheet::Timesheet.should_receive(:new).with(time_log).once.and_return(time_sheet)
      time_sheet.should_receive(:process).with(command_hash)

      Timesheet::Timesheet.run(params)

    end

  end

  context "when processing command" do

    before :each do
      @command = mock("command")
      @timelog = mock("timelog")
      @timesheet = Timesheet::Timesheet.new(@timelog)
    end

    it "should dispatch to the proper command handler" do
      valid_dispatch_cases = {
              :add => :process_add_command,
              :edit => :process_edit_command,
              :report => :process_report_command}

      valid_dispatch_cases.each do |key, value|
        @command.should_receive(:[]).with(:command).once.and_return(key)
        @timesheet.should_receive(value).with(@command).once
        @timesheet.process(@command)
      end
    end

    it "should raise error when the command is not understood" do
      @command.should_receive(:[]).with(:command).once.and_return("invalid_command")
      lambda { @timesheet.process(@command) }.should raise_error RuntimeError
    end

  end

  context "when processing add command" do

    it "should perform an add" do
      command = mock("add command")
      timelog = mock("timelog")
      timesheet = Timesheet::Timesheet.new(timelog)

      project = mock("project")
      start_time = mock("start time")
      end_time = mock("end time")
      entry = mock("time entry")

      command.should_receive(:[]).with(:project).once.and_return(project)
      command.should_receive(:[]).with(:start).once.and_return(start_time)
      command.should_receive(:[]).with(:end).once.and_return(end_time)
      command.should_receive(:[]).with(:comment).once.and_return(nil)
      TimeEntry.should_receive(:new).with(project, start_time, end_time, nil).and_return(entry)
      timelog.should_receive(:add).with(entry)
      
      timesheet.process_add_command(command)
    end

  end

  context "when processing edit command" do

    it "should perform an edit" do
      command = mock("dump command")
      timelog = mock("timelog")
      timesheet = Timesheet::Timesheet.new(timelog)
      time_report = mock("time report")
      entries = mock("entries")

      command.should_receive(:delete).with(:record_number).once.and_return(100)
      timelog.should_receive(:update).with(100, command)
      timelog.should_receive(:find).with(100).once.and_return(entries)
      TimeReport.should_receive(:new).with([entries]).once.and_return(time_report)
      time_report.should_receive(:report).with({:dump => true})

      timesheet.process_edit_command(command)
    end

  end

  context "when processing delete command" do

    it "should perform a delete" do
      command = mock("delete command")
      timelog = mock("timelog")
      timesheet = Timesheet::Timesheet.new(timelog)

      command.should_receive(:delete).with(:record_number).once.and_return(100)
      timelog.should_receive(:delete).with(100)

      timesheet.process_delete_command(command)
    end

  end

  context "when processing report command" do

    it "should produce a report" do
      command = mock("report command")
      timelog = mock("timelog")
      start_time = mock("start time")
      end_time = mock("end time")
      entries = mock("entries")
      time_report = mock("time report")
      timesheet = Timesheet::Timesheet.new(timelog)

      command.should_receive(:[]).with(:start).once.and_return(start_time)
      command.should_receive(:[]).with(:end).once.and_return(end_time)
      timelog.should_receive(:extract_entries).with(start_time, end_time).once.and_return(entries)
      TimeReport.should_receive(:new).with(entries).once.and_return(time_report)
      time_report.should_receive(:report).with(command)

      timesheet.process_report_command(command)      
    end

  end

end
