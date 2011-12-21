# Thanks to: http://opensoul.org/2007/2/13/ranges-include-or-overlap-with-ranges
class Range

  unless (0..5).respond_to?(:cover?)
    alias_method :cover?, :include?
  end

  def overlap?(range)
    self.cover?(range.first) || range.cover?(self.first)
  end

  alias_method :cover_without_range?, :cover?

  def cover_with_range?(value)
    if value.is_a?(Range)
      last = value.exclude_end? ? value.last-1 : value.last
      self.cover?(value.first) && self.cover?(last)
    else
      cover_without_range?(value)
    end
  end

  alias_method :cover?, :cover_with_range?

#  alias_method_chain :include?, :range

end
