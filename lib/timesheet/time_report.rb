require 'time'

class TimeReport

  def initialize(entries)
    @entries = (entries.nil?) ? [] : entries.map { |entry| ReportItem.new(self, entry)}
  end

  attr_accessor :entries
  attr_reader :report_start
  attr_reader :report_end

  def constrain(start_time, end_time)
    @report_start = start_time
    @report_end = end_time
  end

  def report(command_options, outstream = STDOUT)

    if (@entries.nil? || @entries.empty?)
      outstream.puts("No data available.")
    else
      constrain(command_options[:start], command_options[:end])

      dump_report(outstream) if command_options[:dump]
      detail_report(outstream) if command_options[:detail]
      summary_report(outstream) if command_options[:summary]
      byday_report(outstream) if command_options[:byday]
    end
  end

  private

  def dump_report(outstream)
    fields = [
      {:name => "Record:", :method => :record_number },
      {:name => "Project:", :method => :project},
      {:name => "Start:", :method => :formatted_start_time},
      {:name => "End:", :method => :formatted_end_time},
      {:name => "Hours:", :method => :formatted_duration},
      {:name => "Comment:", :method => :comment}
    ]

    item = @entries.first

    label_width = fields.inject(0) { |max, field|  max = [max, field[:name].length].max }
    fields.each { |field| outstream.puts "#{field[:name].ljust(label_width)} #{item.send(field[:method])}" }
    
  end

  def detail_report(outstream)

    fields = [
      {:name => "Id", :method => :formatted_record_number },
      {:name => "Project", :method => :project},
      {:name => "Start - Stop", :method => :formatted_times},
      {:name => "Hours", :method => :formatted_duration},
      {:name => "Comment", :method => :comment}
    ]

    max_widths = Hash.new(0)
    @entries.each do |item|
      fields.each do |field|
        method = field[:method]
        max_widths[method] = [max_widths[method], item.send(method).length].max
      end
    end

    fields.each do |field|
      name = field[:name]
      method = field[:method]
      max_widths[method] = [max_widths[method], name.length].max
    end

    header = "|"
    fields.each { |field| header << " #{field[:name].center(max_widths[field[:method]])} |" }

    separator = "+" + ("-" * (header.length - 2)) + "+"

    outstream.puts separator
    outstream.puts header
    outstream.puts separator

    @entries.sort.each do |item|
      row = "|"
      fields.each do |field|
        row << " #{item.send(field[:method]).ljust(max_widths[field[:method]])} |"
      end
      outstream.puts row
    end

    outstream.puts separator

  end

  def summary_report(outstream)
    summary = Hash.new(0)

    total = @entries.inject(0) do |sum, entry|
      summary[entry.project] += entry.duration.to_i
      sum += entry.duration.to_i
    end

    width = summary.keys.max { |a, b| a.length <=> b.length }.length
    summary.sort.each do |key, value|
      duration = RichUnits::Duration.new(value)
      duration.reset_segments(:hours, :minutes)
      outstream.puts "#{key.rjust(width)} #{duration.strftime("%hh").rjust(4)}#{duration.strftime("%mm").rjust(4)}"
    end

    total_duration = RichUnits::Duration.new(total)
    total_duration.reset_segments(:hours, :minutes)
    outstream.puts "-" * (width + 4 + 4 + 1)
    outstream.puts "#{"Total".rjust(width)} #{total_duration.strftime("%hh").rjust(4)}#{total_duration.strftime("%mm").rjust(4)}"
  end

  def byday_report(outstream)

    hash = {}
    comments = {}
    @entries.each do |entry|
      start_date = Date.new(entry.start_time.year, entry.start_time.month, entry.start_time.day)
      hash[start_date] ||= Hash.new(0)
      hash[start_date][entry.project] += entry.duration.to_i

      comments[start_date] ||= Hash.new { |h, k| h[k] = [] }
      comments[start_date][entry.project] << entry.comment
    end

    hash.sort.each do |entry_date, project_hash|
      outstream.puts entry_date.strftime("%D")
      project_hash.sort.each do |project, duration|
        project_time = RichUnits::Duration.new(duration)
        project_time.reset_segments(:hours, :minutes)
        outstream.puts "\t#{project} #{project_time.strftime("%hh %mm")}"
        comments[entry_date][project].each do |comment|
          outstream.puts "\t - #{comment}"
        end
      end
    end
  end

end