require 'rubygems'
require 'zookeeper'

module EIPClean
  class EIP
  
    attr_reader :zoo_connection, :found_hypers_return_output # :hypers, :owner, :found_hypers
    attr_accessor :channel, :value, :verbose, :dryrun
    def initialize(value, channel, verbose, dryrun)
      # @options = EIPClean::Options.new(argv)
      @zoo_connection = Zookeeper.new("zookeeper-1:2181")
      @value = value
      @hypers = ["hyper-1","hyper-2","hyper-3","hyper-4","hyper-5","hyper-6","hyper-7","hyper-8","hyper-9","hyper-10"]
      @channel = channel # "hsltv3pp-iaas"
      @verbose = verbose
      @dryrun = dryrun
      @owner = self.getowner()
      @found_hypers,@found_hypers_return_output = self.find_hypers()
    end
  
    def do_ssh_cmd(node, cmd)
      ssh_cmd = "ssh -o StrictHostKeyChecking=no #{node} \"#{cmd}\""
      return_output = ""
      return_output << "running the following ssh command: #{ssh_cmd}\n" unless @verbose == false
      return_output << `#{ssh_cmd}`
      return return_output
    end  

    # Placeholder for future functionality: if not given a default hyper list, query a zookeeper server for it
    # We don't use the zookeeper gem API for this since it's not completely compatible with our version 
    # of zookeeper server (3.2.2), so instead use bash shell and zkCli.sh 
    def gethyperlist
      # /hsltv3prod-iaas/rack1/jids 
      # racks = zoo_connection.get_children(:path => "/hsltv3prod-iaas")
      racks = `ssh zookeeper-1 "/opt/ibm-zookeeper-3.2.2/bin/zkCli.sh ls /#{@channel}" |tail -1`
      puts "racks are #{racks}" unless @verbose == false
    end
  
    def getowner
      getresult = zoo_connection.get(:path => "/#{@channel}/resource_locks/IPResource/#{@value}/lock-0000000000")
      # need to include error checking here in case the channel doesn't exist
      if getresult[:data].nil? 
        return nil
      else
        owner = /.*\.(.*)\@.*/.match(getresult[:data]) 
        # puts "#{@value} owner: #{owner[1]}" 
        return owner[1]
      end
    end

    # return a list of hypers in which this ip address is found
    # TODO: right now we're just checking for bad 'ip addr' entries, we could also 
    #   check for bad 'iptables-save' entries that don't have corresponding 'ip addr' entries
    def find_hypers
      return_output = ""
      return_output << "Running in dry run mode.  No changes will be made to EIP config on any hypervisor.\n" unless @dryrun == false
      found_hypers = []
      @hypers.each do |hyper| 
        return_output << "#{hyper}: " unless @verbose == false
        ssh_cmd = "ssh -o StrictHostKeyChecking=no #{hyper} \"ip addr list br0 | grep #{@value}\""
        ssh_cmd_output = `#{ssh_cmd}`
        unless ssh_cmd_output.empty?  
          found_hypers << hyper 
        end
        return_output << "#{ssh_cmd_output}\n" unless @verbose == false
      end
      return found_hypers,return_output
    end

    def checkip
      return_output = ""
      case
      when @owner.nil? && @found_hypers.empty?
        return_output << "EIP #{@value} has no owner and is configured on no hypers."
      when @owner.nil? == false && @found_hypers.empty?
        return_output << "EIP #{@value} has owner #{@owner} but is not configured on any hyper."
      when @owner.nil? == false && @found_hypers.count == 1
        return_output << "CORRECT CONFIG: EIP #{@value} has owner #{@owner} and is configured on a single hyper."
      when @owner.nil? == false && @found_hypers.count > 1
        return_output << "ERROR CONDITION: EIP #{@value} has owner #{@owner} and is configured on the following hypers:"
        return_output << "#{@found_hypers.join(" ")}"
        return_output << self.cleanup
      else
        return_output << "ERROR: Something unexpected happened."
      end
      return return_output
    end

    def cleanup
      return_output = ""
      bad_hypers = @found_hypers
      bad_hypers.delete_if { |hyper| hyper == @owner }
      return_output << "Removing incorrect iptables entries from the following hypers: "
      return_output << "#{bad_hypers.join(" ")}"

      return_output << "\n" unless @verbose == false

      bad_hypers.each do |hyper|
        return_output << "cleaning up #{hyper} ..." unless @verbose == false

        # find the bad 'ip addr' entry
        ip_addr = do_ssh_cmd(hyper,"ip addr|grep #{@value}")
        return_output << "output of \"ip addr\" command: #{ip_addr}" unless @verbose == false

        # grab the ip/netmask
        addrplusmask = ip_addr.split()[1]
       
        # grab the interface
        interface = ip_addr.split()[4]

        # clean the bad 'ip addr' entry
        ipaddr_cleanup_cmd = "ip addr del #{addrplusmask} dev #{interface}"
        return_output << "\'ip addr\' cleanup command is: \"#{ipaddr_cleanup_cmd}\"" unless @verbose == false
        do_ssh_cmd(hyper, ipaddr_cleanup_cmd) unless @dryrun == true

        # find the bad iptables entry
        iptables_rule = do_ssh_cmd(hyper,"iptables-save|grep #{@value}")
        return_output << "iptables rule to be cleaned up: #{iptables_rule}" unless @verbose == false

        # clean the bad iptables entry
        iptables_cleanup_cmd = "iptables -t nat -D #{iptables_rule[2..iptables_rule.length].chop}"
        return_output << "iptables cleanup command is: \"#{iptables_cleanup_cmd}\"" unless @verbose == false
        do_ssh_cmd(hyper, iptables_cleanup_cmd) unless @dryrun == true

        return_output << "\n" unless @verbose == false 
      end 
      return return_output
    end

    # this def used only for debug
    def dump_options
      puts "channel is #{@channel}"
      puts "eip value is #{@value}"
      puts "verbose options is #{@verbose}"
      puts "dryrun options is #{@dryrun}"
    end

  end
end
