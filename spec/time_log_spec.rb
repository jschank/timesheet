require File.dirname(__FILE__) + '/spec_helper.rb'

TEST_FILE = "/var/tmp/timesheet_test.pstore"

describe TimeLog do

  after :all do
    File.delete(TEST_FILE) if File.exists?(TEST_FILE)
  end

  context "adding items" do

    before :all do
      File.delete(TEST_FILE) if File.exists?(TEST_FILE)
      @store = YAML::Store.new(TEST_FILE)
      @time_log = TimeLog.new(@store)
    end


    it "should have no entries initially" do
      @time_log.count.should == 0
    end

    it "should allow time entries to be added" do
      t = Time.now
      entry = TimeEntry.new("Project1", t.hours_ago(2), t)
      entry.record_number.should == nil
      @time_log.add entry
      @time_log.count.should == 1
      entry.record_number.should == 1
    end
  end

  context "finding items" do

    before :all do
      File.delete(TEST_FILE) if File.exists?(TEST_FILE)
      @store = YAML::Store.new(TEST_FILE)
      @time_log = TimeLog.new(@store)

      @time_log.add TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      @time_log.add TimeEntry.new("Project2", Time.local(2009, 12, 2, 9, 0, 0), Time.local(2009, 12, 2, 17, 0, 0))
      @time_log.add TimeEntry.new("Project3", Time.local(2009, 12, 3, 9, 0, 0), Time.local(2009, 12, 3, 17, 0, 0))
      @time_log.add TimeEntry.new("Project4", Time.local(2009, 12, 4, 9, 0, 0), Time.local(2009, 12, 4, 17, 0, 0))
      @time_log.add TimeEntry.new("Project5", Time.local(2009, 12, 5, 9, 0, 0), Time.local(2009, 12, 5, 17, 0, 0))
    end


    it "should raise an error if attempting to find with an unknown index" do
      lambda{@time_log.find(100)}.should raise_error(ArgumentError)
      @time_log.count.should == 5
    end

    it "should not allow finding by record number" do
      entry = @time_log.find(2)
      entry.project.should eql("Project2")
    end

  end

  context "deleting items" do

    before :all do
      File.delete(TEST_FILE) if File.exists?(TEST_FILE)
      @store = YAML::Store.new(TEST_FILE)
      @time_log = TimeLog.new(@store)

      @time_log.add TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      @time_log.add TimeEntry.new("Project2", Time.local(2009, 12, 2, 9, 0, 0), Time.local(2009, 12, 2, 17, 0, 0))
      @time_log.add TimeEntry.new("Project3", Time.local(2009, 12, 3, 9, 0, 0), Time.local(2009, 12, 3, 17, 0, 0))
      @time_log.add TimeEntry.new("Project4", Time.local(2009, 12, 4, 9, 0, 0), Time.local(2009, 12, 4, 17, 0, 0))
      @time_log.add TimeEntry.new("Project5", Time.local(2009, 12, 5, 9, 0, 0), Time.local(2009, 12, 5, 17, 0, 0))
    end


    it "should raise an error if attempting to delete an unknown index" do
      lambda{@time_log.delete(100)}.should raise_error(ArgumentError)
      @time_log.count.should == 5
    end

    it "should not allow conflicting entries to be added" do
      conflicting_entry = TimeEntry.new("Conflicting", Time.local(2009, 12, 2, 12, 0, 0), Time.local(2009, 12, 2, 13, 0, 0))
      lambda { @time_log.add conflicting_entry }.should raise_error(ArgumentError) 
      @time_log.count.should == 5
    end

  end

  context "editing items" do

    before :all do
      File.delete(TEST_FILE) if File.exists?(TEST_FILE)
      @store = YAML::Store.new(TEST_FILE)
      @time_log = TimeLog.new(@store)

      @time_log.add TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      @time_log.add TimeEntry.new("Project2", Time.local(2009, 12, 2, 9, 0, 0), Time.local(2009, 12, 2, 17, 0, 0))
      @time_log.add TimeEntry.new("Project3", Time.local(2009, 12, 3, 9, 0, 0), Time.local(2009, 12, 3, 17, 0, 0))
      @time_log.add TimeEntry.new("Project4", Time.local(2009, 12, 4, 9, 0, 0), Time.local(2009, 12, 4, 17, 0, 0))
      @time_log.add TimeEntry.new("Project5", Time.local(2009, 12, 5, 9, 0, 0), Time.local(2009, 12, 5, 17, 0, 0))
    end

    it "should notify with an error if the edited item's index cannot be found" do
      properties = { :project => "New Project" }
      lambda{@time_log.update(100, properties)}.should raise_error(ArgumentError)
    end

    it "should allow updating of existing items" do
      properties = {:project => "some new project"}
      @time_log.update(2, properties)
      @time_log.count.should == 5

      entry = @time_log.find(2)
      entry.project.should eql("some new project")
    end

    it "should allow updating of existing item start time" do
      properties = {:start => Time.local(2009, 12, 2, 7, 0, 0)}
      @time_log.update(2, properties)
      @time_log.count.should == 5

      entry = @time_log.find(2)
      entry.start_time.should eql( Time.local(2009, 12, 2, 7, 0, 0))
    end

    it "should notify with an error if the new times will overlap with existing items" do
      properties = {:end => Time.local(2009, 12, 3, 10, 0, 0)}
      lambda{@time_log.update(2, properties)}.should raise_error(ArgumentError)
    end

  end

  context "extracting items" do

    before :all do
      File.delete(TEST_FILE) if File.exists?(TEST_FILE)
      @store = YAML::Store.new(TEST_FILE)
      @time_log = TimeLog.new(@store)

      @time_log.add TimeEntry.new("Project1", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 17, 0, 0))
      @time_log.add TimeEntry.new("Project2", Time.local(2009, 12, 2, 9, 0, 0), Time.local(2009, 12, 2, 17, 0, 0))
      @time_log.add TimeEntry.new("Project3", Time.local(2009, 12, 3, 9, 0, 0), Time.local(2009, 12, 3, 17, 0, 0))
      @time_log.add TimeEntry.new("Project4", Time.local(2009, 12, 4, 9, 0, 0), Time.local(2009, 12, 4, 17, 0, 0))
      @time_log.add TimeEntry.new("Project5", Time.local(2009, 12, 5, 9, 0, 0), Time.local(2009, 12, 5, 17, 0, 0))
    end

    it "should return an empty array if no items are in the range" do
      entries = @time_log.extract_entries( Time.local(2009, 11, 1, 9, 0, 0), Time.local(2009, 11, 10, 17, 0, 0))
      entries.should be_empty
    end

    it "should return a collection of items that are covered by the range" do
      entries = @time_log.extract_entries( Time.local(2009, 12, 2, 12, 0, 0), Time.local(2009, 12, 4, 12, 0, 0))
      entries.count.should == 3
    end

    it "should notify with an error if the new times will overlap with existing items" do
      properties = {:end => Time.local(2009, 12, 3, 10, 0, 0)}
      lambda{@time_log.update(2, properties)}.should raise_error(ArgumentError)
    end

  end

end