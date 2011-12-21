require File.dirname(__FILE__) + '/spec_helper.rb'
require 'chronic'

describe TimesheetParser do

  context "when given empty parameters" do

    before :each do
    end

    it "should show usage" do
      lambda {TimesheetParser.parse([])}.should raise_error SystemExit
    end

  end

  context "when parsing in general" do
    
    it "should dump the options hash if the debug flag is set" do

      outstream = StringIO.new
      hash = TimesheetParser.parse(%w[--debug add -p a\ project\ name --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm --comment a\ comment], outstream)
      outstream.string().should include("Command-line options hash...")
    end

    it "should report an error if the entire command line is not parsed" do
      lambda {TimesheetParser.parse(%w[edit -r 100 -p a\ project\ name fiddle-dee-dee])}.should raise_error ArgumentError
    end

  end

  context "when parsing add command" do

    before :each do
    end

    it "should fail on a bare add" do
      lambda {TimesheetParser.parse(["add"])}.should raise_error SystemExit
    end

    it "should parse a valid complete add command" do
      hash = TimesheetParser.parse(%w[add -p a\ project\ name --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm --comment a\ comment])
      hash[:command].should eql(:add)
      hash[:project].should eql("a project name")
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
      hash[:comment].should eql("a comment")
    end

    it "should allow comment to be optional" do
      hash = TimesheetParser.parse(%w[add -p a\ project\ name --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm])
      hash[:command].should eql(:add)
      hash[:project].should eql("a project name")
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
    end

    it "should require project" do
      lambda {TimesheetParser.parse(%w[add --start 12/1/2009\at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm])}.should raise_error SystemExit
    end

    it "should require start time" do
      lambda {TimesheetParser.parse(%w[add -p a\ project\ name --end 12/1/2009\ at\ 2:00\ pm --comment a\ comment])}.should raise_error SystemExit
    end

    it "should require end time" do
      lambda {TimesheetParser.parse(%w[add -p a\ project\ name --start 12/1/2009\at\ 11:00\ am --comment a\ comment])}.should raise_error SystemExit
    end

  end

  context "when parsing list command" do

    before :each do
    end

    it "should accept a bare list" do
      lambda {TimesheetParser.parse(["list"])}.should_not raise_error SystemExit
    end

    it "should accept a start and end time" do
      hash = TimesheetParser.parse(%w[list --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm])
      hash[:command].should eql(:report)
      hash[:detail].should be_true
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
    end

    it "should accept --today" do      
      hash = TimesheetParser.parse(%w[list --today])
      hash[:command].should eql(:report)
      hash[:detail].should be_true
      hash[:start].should eql(Chronic.parse('today at 12 am'))
      hash[:end].should eql(Chronic.parse('tomorrow at 12 am'))
    end

    it "should fail if start date and --today are used" do
      lambda {TimesheetParser.parse(%w[list --today --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm])}.should raise_error SystemExit
    end

    it "should fail if start date is missing end date" do
      lambda {TimesheetParser.parse(%w[list --start 12/1/2009\ at\ 11:00\ am])}.should raise_error SystemExit
    end

  end

  context "when parsing edit command" do

    before :each do
    end

    it "should fail on a bare edit" do
      lambda {TimesheetParser.parse(["edit"])}.should raise_error SystemExit
    end

    it "should parse a valid complete edit command" do
      hash = TimesheetParser.parse(%w[edit -r 100 -p a\ project\ name --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm --comment a\ comment])
      hash[:command].should eql(:edit)
      hash[:record_number].should eql(100)
      hash[:project].should eql("a project name")
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
      hash[:comment].should eql("a comment")
    end

    it "should allow just comment" do
      hash = TimesheetParser.parse(%w[edit -r 12 -c a\ new\ comment])
      hash[:command].should eql(:edit)
      hash[:record_number].should eql(12)
      hash[:project].should be_nil
      hash[:start].should be_nil
      hash[:end].should be_nil
      hash[:comment].should eql("a new comment")
    end

    it "should allow just project" do
      hash = TimesheetParser.parse(%w[edit --record-number 200 --project a\ new\ project])
      hash[:command].should eql(:edit)
      hash[:record_number].should eql(200)
      hash[:project].should eql("a new project")
      hash[:start].should be_nil
      hash[:end].should be_nil
      hash[:comment].should be_nil
    end

    it "should allow just start time" do
      hash = TimesheetParser.parse(%w[edit -r 1 -s 12/1/2009\ at\ 11:00\ am])
      hash[:command].should eql(:edit)
      hash[:record_number].should eql(1)
      hash[:project].should be_nil
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should be_nil
      hash[:comment].should be_nil
    end

    it "should allow just end time" do
      hash = TimesheetParser.parse(%w[edit -r 1 -e 12/1/2009\ at\ 2:00\ pm])
      hash[:command].should eql(:edit)
      hash[:record_number].should eql(1)
      hash[:project].should be_nil
      hash[:start].should be_nil 
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
      hash[:comment].should be_nil
    end

  end

  context "when parsing delete command" do

    before :each do
    end

    it "should fail on a bare delete" do
      lambda {TimesheetParser.parse(["delete"])}.should raise_error SystemExit
    end

    it "should parse a valid delete command" do
      hash = TimesheetParser.parse(%w[delete -r 100])
      hash[:command].should eql(:delete)
      hash[:record_number].should eql(100)
    end

  end

  context "when parsing report command" do

    before :each do
    end

    it "should accept a bare report" do
      lambda {TimesheetParser.parse(["report"])}.should_not raise_error SystemExit
    end

    it "should parse a valid complete report command" do
      hash = TimesheetParser.parse(%w[report --summary --start 12/1/2009\ at\ 11:00\ am --end 12/1/2009\ at\ 2:00\ pm])
      hash[:command].should eql(:report)
      hash[:summary].should be_true
      hash[:detail].should be_false
      hash[:byday].should be_false
      hash[:start].should eql(Time.local(2009, 12, 1, 11, 0, 0))
      hash[:end].should eql(Time.local(2009, 12, 1, 14, 0, 0))
    end

    it "should reject conflicting parameters" do
      lambda {TimesheetParser.parse(%w[report --summary --detail])}.should raise_error SystemExit
    end

    it "should reject start without end" do
      lambda {TimesheetParser.parse(%w[report --summary --start 12/1/2009\at\ 11:00\ am ])}.should raise_error SystemExit
    end

    it "should allow shortcuts" do
      hash = TimesheetParser.parse(%w[report --byday --yesterday])
      hash[:command].should eql(:report)
      hash[:summary].should be_false
      hash[:detail].should be_false
      hash[:byday].should be_true
      hash[:start].should eql(Chronic.parse('yesterday at 12 am'))
      hash[:end].should eql(Chronic.parse('today at 12 am'))
    end

  end

  context "when given nonsense" do

    before :each do
    end

    it "should reject unknown commands" do
      lambda {TimesheetParser.parse(%w[trundlebug])}.should raise_error SystemExit
    end

  end

end