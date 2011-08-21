require 'lib/eipclean.rb'
require 'lib/options.rb'

class EipController < ApplicationController
  def get
  end

  def displayresult
  end

  def index
#    @parameters = params
#    @dryrun = params[:dryrun]
#    @verbose = params[:verbose]
#    @value = params[:value]
#    @channel = params[:channel]
 
   @eip = EIPClean::EIP.new(params[:value],params[:channel],params[:verbose],params[:dryrun]) 
   @found_hypers_return_output = @eip.found_hypers_return_output 
   @checkip_output = @eip.checkip
   @eip.zoo_connection.close
 
  end
end
