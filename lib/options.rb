require 'optparse'

module EIPClean
  class Options

    attr_reader :verbose
    attr_reader :dryrun
    attr_reader :channel
    attr_reader :value

    def initialize(argv)
      @verbose = false
      @dryrun = false
      @channel = nil
      @value = nil
      parse(argv)
    end
 
  private
    def parse(argv)
      OptionParser.new do|opts|
        # Set a banner, displayed at the top of the help screen.
        opts.banner = "Usage: eipclean [options] -c zookeeper_channel -i eip ..."

        # The following is a required option: zookeeper channel from which to query EIP owner, etc.
        opts.on("-c", "--channel CHANNEL",String,"(Required) zookeeper channel") do |chan|
          @channel = chan
        end

        # The following is a required option: elastic IP address which we're trying to clean up from 
        # non-owner hypervisors
        opts.on("-i", "--ip EIP",String,"(Required) elastic IP address") do |val|
          @value = val
        end

        # Run in verbose mode, i.e., print out results of query of each hypervisor in the list
        opts.on( '-v', '--verbose', 'Output verbose information' ) do
          @verbose = true
        end

        # Run in 'dry run' mode, i.e., query status but don't change anything as a result
        opts.on( '-d', '--dryrun', 'Do a dry run (don\'t actually change anything)' ) do
          @dryrun = true
        end

        # This displays the help screen, all programs are assumed to have this option.
        opts.on( '-h', '--help', 'Show this message' ) do
          puts opts
          exit
        end

        begin
          argv = ["-h"] if argv.empty?
          opts.parse!(argv)
        rescue OptionParser::ParseError => e
          STDERR.puts e.message, "\n", opts
          exit(-1)
        end

      end
    end
  end
end

