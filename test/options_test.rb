require 'rubygems'
require 'test/unit'
require 'shoulda'
require '../lib/eipclean.rb'
require '../lib/options.rb'

class TestOptions < Test::Unit::TestCase
  context "options" do
    setup do
      @testargs = ["-d", "-v", "-c", "hsltv3pp-iaas", "-i", "9.12.216.117"]
      @eip = EIPClean::EIP.new(@testargs)
    end

    should "return sane output given real option input" do
      assert_equal "hsltv3pp-iaas", @eip.channel
      assert_equal "9.12.216.117", @eip.value
      assert_equal true, @eip.dryrun
      assert_equal true, @eip.verbose
    end

  end
end

