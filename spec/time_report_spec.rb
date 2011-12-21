require File.dirname(__FILE__) + '/spec_helper.rb'

describe TimeReport do

  before :each do
    @entries =
            [TimeEntry.new("ProjectA", Time.local(2009, 12, 1, 9, 0, 0), Time.local(2009, 12, 1, 12, 0, 0), "comment 1"),
             TimeEntry.new("ProjectB", Time.local(2009, 12, 1, 1, 0, 0), Time.local(2009, 12, 1, 17, 0, 0), "comment 2"),
             TimeEntry.new("ProjectA", Time.local(2009, 12, 3, 9, 0, 0), Time.local(2009, 12, 3, 17, 0, 0), "comment 3"),
             TimeEntry.new("ProjectB", Time.local(2009, 12, 4, 9, 0, 0), Time.local(2009, 12, 4, 17, 0, 0), "comment 4"),
             TimeEntry.new("ProjectC", Time.local(2009, 12, 5, 9, 0, 0), Time.local(2009, 12, 5, 17, 0, 0), "comment 5")]
    @time_report = TimeReport.new(@entries)
  end

  it "should be able to trim its entries to a specific time span" do
    @time_report.constrain(Time.local(2009, 12, 1, 11, 0, 0), Time.local(2009, 12, 5, 12, 0, 0))
    @time_report.entries[0].start_time.should eql(Time.local(2009, 12, 1, 11, 0, 0))
    @time_report.entries[-1].end_time.should eql(Time.local(2009, 12, 5, 12, 0, 0))
  end

  it "should leave entries alone when the trim span is outside the entry range" do
    @time_report.constrain(Time.local(2009, 11, 1, 0, 0, 0), Time.local(2009, 12, 31, 0, 0, 0))
    @time_report.entries[0].start_time.should eql(Time.local(2009, 12, 1, 9, 0, 0))
    @time_report.entries[-1].end_time.should eql(Time.local(2009, 12, 5, 17, 0, 0))
  end

  it "should show 'no data' if entries is missing" do
    stream = StringIO.new
    time_report = TimeReport.new(nil)
    command_options = {:summary => true, :start => Time.local(2009, 12, 1), :end => Time.local(2009, 12, 6)}
    time_report.report(command_options, stream)
    stream.string.should eql("No data available.\n")    
  end

  it "should show 'no data' if there are no entries to report" do
    stream = StringIO.new
    time_report = TimeReport.new([])
    command_options = {:summary => true, :start => Time.local(2009, 12, 1), :end => Time.local(2009, 12, 6)}
    time_report.report(command_options, stream)
    stream.string.should eql("No data available.\n")
  end

  it "should be able to produce a dump report" do
    command_options = {:dump => true}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
Record:  N/A
Project: ProjectA
Start:   12/01/2009 at 09:00:00 AM
End:     12/01/2009 at 12:00:00 PM
Hours:   3h 0m
Comment: comment 1
EOS
)
  end

  it "should be able to produce a detail report" do
    command_options = {:detail => true, :start => Time.local(2009, 12, 1), :end => Time.local(2009, 12, 6)}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
+------------------------------------------------------------------------------+
|  Id   | Project  |             Start - Stop             | Hours  |  Comment  |
+------------------------------------------------------------------------------+
|     0 | ProjectB |  12/01/2009 at 01:00 AM to 05:00 PM  | 16h 0m | comment 2 |
|     0 | ProjectA |  12/01/2009 at 09:00 AM to 12:00 PM  | 3h 0m  | comment 1 |
|     0 | ProjectA |  12/03/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 3 |
|     0 | ProjectB |  12/04/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 4 |
|     0 | ProjectC |  12/05/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 5 |
+------------------------------------------------------------------------------+
EOS
)
  end

  it "should be able to produce a detail report with slice indicators" do
    command_options = {:detail => true, :start => Time.local(2009, 12, 1, 11, 0, 0), :end => Time.local(2009, 12, 5, 12, 0, 0)}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
+-----------------------------------------------------------------------------+
|  Id   | Project  |             Start - Stop             | Hours |  Comment  |
+-----------------------------------------------------------------------------+
|     0 | ProjectA | <12/01/2009 at 11:00 AM to 12:00 PM  | 1h 0m | comment 1 |
|     0 | ProjectB | <12/01/2009 at 11:00 AM to 05:00 PM  | 6h 0m | comment 2 |
|     0 | ProjectA |  12/03/2009 at 09:00 AM to 05:00 PM  | 8h 0m | comment 3 |
|     0 | ProjectB |  12/04/2009 at 09:00 AM to 05:00 PM  | 8h 0m | comment 4 |
|     0 | ProjectC |  12/05/2009 at 09:00 AM to 12:00 PM> | 3h 0m | comment 5 |
+-----------------------------------------------------------------------------+
EOS
)
  end

  it "should be able to produce a detail report" do
    command_options = {:detail => true, :start => Time.local(2009, 11, 1), :end => Time.local(2009, 12, 31)}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
+------------------------------------------------------------------------------+
|  Id   | Project  |             Start - Stop             | Hours  |  Comment  |
+------------------------------------------------------------------------------+
|     0 | ProjectB |  12/01/2009 at 01:00 AM to 05:00 PM  | 16h 0m | comment 2 |
|     0 | ProjectA |  12/01/2009 at 09:00 AM to 12:00 PM  | 3h 0m  | comment 1 |
|     0 | ProjectA |  12/03/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 3 |
|     0 | ProjectB |  12/04/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 4 |
|     0 | ProjectC |  12/05/2009 at 09:00 AM to 05:00 PM  | 8h 0m  | comment 5 |
+------------------------------------------------------------------------------+
EOS
)
  end

  it "should be able to produce a summary report" do
    command_options = {:summary => true, :start => Time.local(2009, 12, 1), :end => Time.local(2009, 12, 6)}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
ProjectA  11h  0m
ProjectB  24h  0m
ProjectC   8h  0m
-----------------
   Total  43h  0m
EOS
)
  end

  it "should be able to produce a byday report" do
    @entries << TimeEntry.new("ProjectB", Time.local(2009, 12, 1, 17, 0, 0), Time.local(2009, 12, 1, 19, 0, 0), "another comment")
    @time_report = TimeReport.new(@entries)

    command_options = {:byday => true, :start => Time.local(2009, 12, 1), :end => Time.local(2009, 12, 6)}
    stream = StringIO.new
    @time_report.report(command_options, stream)
    stream.string.should eql( <<EOS
12/01/09
	ProjectA 3h 0m
	 - comment 1
	ProjectB 18h 0m
	 - comment 2
	 - another comment
12/03/09
	ProjectA 8h 0m
	 - comment 3
12/04/09
	ProjectB 8h 0m
	 - comment 4
12/05/09
	ProjectC 8h 0m
	 - comment 5
EOS
)

  end

end