class TimeEntry 

  include Comparable

  def initialize(project, start_time, end_time, comment = nil)

    raise ArgumentError.new("Start time must come before end time") if start_time > end_time

    @project = project
    @start_time = start_time
    @end_time = end_time
    @comment = comment
    @record_number = nil

  end

  attr_accessor :project
  attr_reader :start_time
  attr_reader :end_time
  attr_accessor :comment
  attr_accessor :record_number

  def conflict?(other_entry)
    to_range.overlap? other_entry.to_range
  end

  def start_time=(new_start_time)
    raise ArgumentError.new("Start time must come before end time") if new_start_time > @end_time
    @start_time = new_start_time
  end

  def end_time=(new_end_time)
    raise ArgumentError.new("End time must come after start time") if @start_time > new_end_time
    @end_time = new_end_time
  end

  def duration
    return 0 if @start_time == nil || @end_time == nil
    RichUnits::Duration.new(@end_time - @start_time)
  end

  def <=>(other_time_entry)
    self.start_time <=> other_time_entry.start_time
  end

  def to_range
    Range.new(@start_time, @end_time, true)
  end
  
  def to_s
    label_width = 10
    str = ""
    str << "#{"class:".ljust(label_width)}#{self.class}\n"
    str << "#{"record:".ljust(label_width)}#{record_number}\n"
    str << "#{"project:".ljust(label_width)}#{project}\n"
    str << "#{"start:".ljust(label_width)}#{start_time.strftime("%m/%d/%Y at %I:%M %p")}\n"
    str << "#{"end:".ljust(label_width)}#{end_time.strftime("%m/%d/%Y at %I:%M %p")}\n"
    str << "#{"duration:".ljust(label_width)}#{duration}\n"
    str << "#{"comment:".ljust(label_width)}#{comment}\n"
    
    str
  end

end