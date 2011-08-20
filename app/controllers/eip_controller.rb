class EipController < ApplicationController
  def get
  end

  def displayresult
  end

  def index
    @parameters = params
    @dryrun = params[:dryrun]
    @verbose = params[:verbose]
    @value = params[:value]
    @channel = params[:channel]
  end
end
