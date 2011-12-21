class TimeLog

  def initialize(store)
    @store = store
    @store.transaction do
      @store[:entries] ||= []
      @store[:entry_record_number] ||= 0
    end
  end

  def count
    @store.transaction do
      @store[:entries].count
    end
  end

  def add(entry)
    @store.transaction do
      raise ArgumentError.new("Cannot add an entry which conflicts with existing entries.") if @store[:entries].any? { |e| e.conflict? entry }
      @store[:entry_record_number] += 1
      entry.record_number = @store[:entry_record_number]
      @store[:entries] << entry
    end
  end

  def find(record_number)
    @store.transaction do
      found_entries = @store[:entries].select{|e| e.record_number == record_number}
      raise "Record number #{record_number} is not unique in the database." if found_entries.count > 1
      raise ArgumentError.new("Cannot find an entry with record number #{record_number} to edit") if found_entries.count == 0

      found_entries.first
    end
  end

  def extract_entries(start_time, end_time)
    covered_entries = []
    @store.transaction do
      span_to_cover = Range.new(start_time, end_time, true)
      covered_entries = @store[:entries].select{|e| span_to_cover.overlap? e.to_range }
    end
    covered_entries
  end

  def update(record_number, properties)
    @store.transaction do
      found_entries = @store[:entries].select{|e| e.record_number == record_number}
      raise "Record number #{record_number} is not unique in the database." if found_entries.count > 1
      raise ArgumentError.new("Cannot find an entry with record number #{record_number} to edit") if found_entries.count == 0

      entry = found_entries.first
      entry.project = properties[:project] if properties[:project]
      entry.start_time = properties[:start] if properties[:start]
      entry.end_time = properties[:end] if properties[:end]
      entry.comment = properties[:comment] if properties[:comment]
      raise ArgumentError.new("The new times for this entry conflict with existing entries.") if @store[:entries].any? { |e| e != entry && e.conflict?(entry) }
    end
  end

  def delete(record_number)
    @store.transaction do
      found_entries = @store[:entries].select{|e| e.record_number == record_number}
      raise "Record number #{record_number} is not unique in the database." if found_entries.count > 1
      raise ArgumentError.new("Cannot find an entry with record number #{record_number} to delete.") if found_entries.count == 0

      @store[:entries].delete(found_entries.first)
    end
  end

  
end