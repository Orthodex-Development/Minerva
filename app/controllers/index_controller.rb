class IndexController < ApplicationController
  before_action :conn_to_redis
  after_action :close_redis_conn
  def index
    @results = @redis.keys.select { |e| !e.include?"_" }
  end

  def show
    @id = params[:id]
    @results = {}

    keys = @redis.keys
    keys.each do |key|
      next if !key.include? "_"
      @results[@id.to_sym] ||= {}
      case key
      when "rv_#{@id}" then @results[@id.to_sym][:review] = @redis.get key
      when "sa_rv_#{@id}" then @results[@id.to_sym][:sa_rv] = JSON.parse(@redis.get key)
      when "sg_#{@id}"
        sg = JSON.parse(@redis.get key)
        @results[@id.to_sym][:sg] = sg
        aspect_sentiments = {}
        sg.each do |k, v|
          aspect_sentiments[k] = JSON.parse(@redis.hget "sa_sg_#{@id}", k.to_s)
        end
        @results[@id.to_sym][:asp_s] = aspect_sentiments
      end
    end
  end

  private

  def conn_to_redis
    @redis = Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
  end

  def close_redis_conn
    @redis.close
  end
end
