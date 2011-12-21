require File.dirname(__FILE__) + '/spec_helper.rb'

describe Range do

  it "should detect overlaps" do
    (1..5).overlap?(4..8).should be_true
    (1...5).overlap?(5..10).should be_false
  end

  it "should allow include?" do
    (1..5).include?(2..3).should be_false
    (1..5).include?(4..8).should be_false
    (1..5).include?(3).should be_true
    (1..5).include?(6).should be_false
  end

  context "with times" do

    before(:all) do
      @time = Time.now
  end

    it "should detect overlaps" do
      (@time..@time+5).overlap?(@time+4..@time+8).should be_true
      (@time...@time+5).overlap?(@time+5..@time+10).should be_false
    end

    it "should allow cover?" do
      (@time..@time+5).cover?(@time+2..@time+3).should be_true
      (@time..@time+5).cover?(@time+4..@time+8).should be_false
      (@time..@time+5).cover?(@time+3).should be_true
      (@time..@time+5).cover?(@time+6).should be_false
    end
  end

end