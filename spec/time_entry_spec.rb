require File.dirname(__FILE__) + '/spec_helper.rb'

describe TimeEntry do

  context "Construction" do

    it "should allow initialization of fields" do
      lambda { TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0)) }.should_not raise_error()
    end

    it "should raise ArgumentError if end time is before start time" do
      lambda { TimeEntry.new("Project", Time.local(2009, 12, 1, 17, 0, 0), Time.local(2009, 12, 1, 9, 0, 0)) }.should raise_error(ArgumentError)
    end

  end

  context "Basic Features" do

    before :each do
      @time_entry = TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0), "a comment")
      @time_entry.record_number = 1
    end


    it "should know its initial project" do
      @time_entry.project.should == "Project"
    end

    it "should have an know its initial start time" do
      @time_entry.start_time.should == Time.local(2009, 12, 1, 9, 0, 0)
    end

    it "should know its initial end time" do
      @time_entry.end_time.should == Time.local(2009, 12, 1, 17, 0, 0)
    end

    it "should have an initial comment of nil" do
      time_entry =  TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      time_entry.comment.should == nil
    end

    it "should calculate its duration from start and end times" do
      @time_entry.duration.should == 8.hours
    end

    it "should remember its assigned project" do
      @time_entry.project = "Project2"
      @time_entry.project.should == "Project2"
    end

    it "should raise an ArgumentError if a start_time is assigned that is after the end_time" do
      lambda { @time_entry.start_time = Time.local(2009, 12, 1, 18, 0 , 0) }.should raise_error(ArgumentError)
    end

    it "should raise an ArgumentError if an end_time is assigned that is before the start_time" do
      lambda { @time_entry.end_time = Time.local(2009, 12, 1, 8, 0 , 0) }.should raise_error(ArgumentError)
    end

    it "should remember its assigned start time" do
      time = Time.local(2009, 12, 1, 12, 0, 0)
      @time_entry.start_time = time
      @time_entry.start_time.should == time
    end

    it "should remember its assigned end time" do
      time = Time.local(2009, 12, 1, 12, 0, 0)
      @time_entry.end_time = time
      @time_entry.end_time.should == time
    end

    it "should remember its assigned comment" do
      @time_entry.comment = "Comment"
      @time_entry.comment.should == "Comment"
    end

    it "should not allow assignment to duration" do
      @time_entry.should_not respond_to :duration=
    end
    
    it "should have a to_s method to display its contents" do
      @time_entry.should respond_to :to_s
      @time_entry.to_s.should eql( <<EOS
class:    TimeEntry
record:   1
project:  Project
start:    12/01/2009 at 09:00 AM
end:      12/01/2009 at 05:00 PM
duration: 0 seconds 0 minutes 8 hours 0 days
comment:  a comment
EOS
)
    end

  end

  context "comparison and sorting" do
    before :each do
      @early_entry = TimeEntry.new("Project", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 12, 0, 0))
      @late_entry = TimeEntry.new("Project", Time.local(2009, 12, 1, 13, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
    end

    it "should be comparable to other time entries" do
      @early_entry.should respond_to :<=>
    end

    it "should order before an entry with a later start time" do
      lambda { @early_entry < @late_entry}.should be_true
    end

    it "should order after an entry with an earlier start time" do
      lambda { @late_entry > @early_entry}.should be_true
    end
  end

  context "Conflict detection" do

    it "these should not conflict" do
      entry1 = TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      entry2 = TimeEntry.new("Project2", Time.local(2009, 12, 2, 9, 0, 0), Time.local(2009, 12, 2, 17, 0, 0))

      entry1.conflict?(entry2).should be_false
      entry2.conflict?(entry1).should be_false
    end


    it "should conflict" do
      entry1 = TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      entry2 = TimeEntry.new("Project2", Time.local(2009, 12, 1, 12, 0, 0), Time.local(2009, 12, 1, 20, 0, 0))

      entry1.conflict?(entry2).should be_true
      entry2.conflict?(entry1).should be_true
    end

    it "should conflict" do
      entry1 = TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      entry2 = TimeEntry.new("Project2", Time.local(2009, 12, 1, 12, 0, 0), Time.local(2009, 12, 1, 14, 0, 0))

      entry1.conflict?(entry2).should be_true
      entry2.conflict?(entry1).should be_true
    end

    it "should not conflict if its start time is the same as another entries end time" do
      entry1 = TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 12, 0, 0))
      entry2 = TimeEntry.new("Project2", Time.local(2009, 12, 1, 12, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))

      entry1.conflict?(entry2).should be_false
      entry2.conflict?(entry1).should be_false

    end

  end

end