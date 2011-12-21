require 'delegate'

class ReportItem 

  include Comparable

  def initialize( report, time_entry)
    @time_entry = time_entry
    @report = report
  end

  def start_time_sliced?
    @time_entry.to_range.cover?(@report.report_start)
  end
  
  def project
    @time_entry.project
  end

  def start_time
    if start_time_sliced?
      @report.report_start
    else
      @time_entry.start_time
    end
  end

  def duration
    return 0 if start_time == nil || end_time == nil
    RichUnits::Duration.new(end_time - start_time)
  end


  def end_time_sliced?
    @time_entry.to_range.cover?(@report.report_end)
  end

  def start_slice_indication
    (start_time_sliced?) ? '<' : ' '
  end

  def end_slice_indication
    (end_time_sliced?) ? '>' : ' '
  end

  def end_time
    if end_time_sliced?
      @report.report_end
    else
      @time_entry.end_time
    end
  end

  def formatted_record_number
    sprintf("%5d", @time_entry.record_number || 0)    
  end

  def formatted_start_time
    start_time.strftime("%m/%d/%Y at %I:%M:%S %p")
  end

  def formatted_end_time
    end_time.strftime("%m/%d/%Y at %I:%M:%S %p")
  end

  def formatted_times
    str = ""
    str << start_slice_indication
    str << start_time.strftime("%m/%d/%Y at %I:%M %p")
    str << " to "
    str << end_time.strftime("%m/%d/%Y at ") if ((start_time.year != end_time.year) || (start_time.yday != end_time.yday))
    str << end_time.strftime("%I:%M %p")
    str << end_slice_indication
  end

  def comment
    @time_entry.comment || ""
  end

  def record_number
    @time_entry.record_number || "N/A"
  end

  def formatted_duration
    str = ""
    str << duration.strftime("%d Days ") if duration.days > 0
    str << duration.strftime("%hh %mm")
  end

  def <=>(other_time_entry)
    self.start_time <=> other_time_entry.start_time
  end

end