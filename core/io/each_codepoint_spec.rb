require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/codepoints'

# See redmine #1667
ruby_version_is "1.9" do
  describe "IO#each_codepoint" do
    it_behaves_like(:io_codepoints, :codepoints)
  end

  describe "IO#each_codepoint" do
    before :each do
      @io = IOSpecs.lines_fixture
    end

    after :each do
      @io.close
    end

    it "calls the given block" do
      r = []
      @io.each_codepoint { |c| r << c }
      r[24].should == 232
      r.last.should == 10
    end

    it "returns self" do
      @io.each_codepoint { |l| l }.should equal(@io)
    end
  end
end

