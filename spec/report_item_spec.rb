require File.dirname(__FILE__) + '/spec_helper.rb'

describe ReportItem do

  describe "#start_time" do

    context "when constrained by the parent report" do

      it "should use the report start time" do
        time_entries = [ TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 18, 0, 0)) ]
        time_report = TimeReport.new(time_entries)
        time_report.constrain( Time.local(2009, 12, 1, 12, 0, 0), Time.local(2009, 12, 2, 12, 0, 0))

        time_report.entries[0].start_time.should eql(time_report.report_start)
      end

    end

    context "when not constrained by the parent report" do

      it "should use the entry's start time" do
        time_entries = [ TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 18, 0, 0)) ]
        time_report = TimeReport.new(time_entries)
        time_report.constrain( Time.local(2009, 11, 1, 12, 0, 0), Time.local(2009, 12, 2, 12, 0, 0))

        time_report.entries[0].start_time.should eql(time_entries[0].start_time)
      end
    end

  end

  describe "#end_time" do

    context "when constrained by the parent report" do

      it "should use the report end time" do
        time_entries = [ TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 18, 0, 0)) ]
        time_report = TimeReport.new(time_entries)
        time_report.constrain( Time.local(2009, 11, 1, 12, 0, 0), Time.local(2009, 12, 1, 12, 0, 0))

        time_report.entries[0].end_time.should eql(time_report.report_end)
      end

    end

    context "when not constrained by the parent report" do

      it "should use the entry's end time" do
        time_entries = [ TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 18, 0, 0)) ]
        time_report = TimeReport.new(time_entries)
        time_report.constrain( Time.local(2009, 11, 1, 12, 0, 0), Time.local(2009, 12, 2, 12, 0, 0))

        time_report.entries[0].end_time.should eql(time_entries[0].end_time)

      end

    end

  end

end

describe "formatting behavior" do

  before :each do
    @report = mock("TimeReport")
    @time_entry = mock("TimeEntry")
    @report_item = ReportItem.new(@report, @time_entry)
  end

  it "should format the record number" do
    @time_entry.should_receive(:record_number).once.and_return(1)
    @report_item.formatted_record_number.should eql("    1")
  end

  describe "#times" do

    context "when start and end times are on the same day" do
      it "should show the date only once" do        
        entry_start  = Time.local(2009, 12, 1, 9, 0, 0)
        entry_end    = Time.local(2009, 12, 1, 17, 0, 0)
        report_start = Time.local(2009, 12, 1, 8, 0, 0)
        report_end   = Time.local(2009, 12, 1, 18, 0, 0)
        
        @time_entry.should_receive(:to_range).any_number_of_times.and_return(entry_start..entry_end)
        @time_entry.should_receive(:start_time).any_number_of_times.and_return(entry_start)
        @time_entry.should_receive(:end_time).any_number_of_times.and_return(entry_end)

        @report.should_receive(:report_start).any_number_of_times.and_return(report_start)
        @report.should_receive(:report_end).any_number_of_times.and_return(report_end)
        
        @report_item.formatted_times.should eql(" 12/01/2009 at 09:00 AM to 05:00 PM ")
      end
    end

    context "when start and end times are on the same day and the start end end times are sliced" do
      it "should show the date only once" do
        entry_start  = Time.local(2009, 12, 1, 9, 0, 0)
        entry_end    = Time.local(2009, 12, 1, 17, 0, 0)
        report_start = Time.local(2009, 12, 1, 10, 0, 0)
        report_end   = Time.local(2009, 12, 1, 16, 0, 0)
        
        @time_entry.should_receive(:to_range).any_number_of_times.and_return(entry_start..entry_end)
        @time_entry.should_receive(:start_time).any_number_of_times.and_return(entry_start)
        @time_entry.should_receive(:end_time).any_number_of_times.and_return(entry_end)

        @report.should_receive(:report_start).any_number_of_times.and_return(report_start)
        @report.should_receive(:report_end).any_number_of_times.and_return(report_end)
        
        @report_item.formatted_times.should eql("<12/01/2009 at 10:00 AM to 04:00 PM>")
      end
    end

    context "when start and end times are on different days" do
      it "should show the date for both start and end" do
        entry_start  = Time.local(2009, 12, 1, 9, 0, 0)
        entry_end    = Time.local(2009, 12, 2, 18, 0, 0)
        report_start = Time.local(2009, 12, 1, 8, 0, 0)
        report_end   = Time.local(2009, 12, 2, 19, 0, 0)
        
        @time_entry.should_receive(:to_range).any_number_of_times.and_return(entry_start..entry_end)
        @time_entry.should_receive(:start_time).any_number_of_times.and_return(entry_start)
        @time_entry.should_receive(:end_time).any_number_of_times.and_return(entry_end)

        @report.should_receive(:report_start).any_number_of_times.and_return(report_start)
        @report.should_receive(:report_end).any_number_of_times.and_return(report_end)
        
        @report_item.formatted_times.should eql(" 12/01/2009 at 09:00 AM to 12/02/2009 at 06:00 PM ")
      end

    end
  end

  describe "#duration" do

    context "when the duration is longer than one day" do

      it "should include days in the display" do
        @report_item.should_receive(:duration).any_number_of_times.and_return(RichUnits::Duration.new(30.hours.to_i + 15.minutes.to_i))
        # @report_item.should_receive(:duration).any_number_of_times.and_return(RichUnits::Duration.new(30.hours.to_i + 15.minutes.to_i))
        @report_item.formatted_duration.should eql("1 Days 6h 15m")
      end

    end

    context "when the duration is less than one day" do

      it "should not include days in the display" do
        # report_item = ReportItem.new(@report, @time_entry)
        @report_item.stub(:duration).any_number_of_times.and_return(RichUnits::Duration.new(12.hours.to_i + 15.minutes.to_i))

        # report_item.should_receive(:duration).any_number_of_times.and_return(RichUnits::Duration.new(12.hours.to_i + 15.minutes.to_i))
        @report_item.formatted_duration.should eql("12h 15m")
      end
    end

  end

end
