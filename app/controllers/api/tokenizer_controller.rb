module Api
  class TokenizerController < ApplicationController
    wrap_parameters :token

    def tokenize
      $REDIS ||= Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
      # Send individual aspects for review
      AspectDetectionWorker.perform_async(token_params[:review], token_params[:movie_id], token_params[:user_id])
      render :json => {:message => "received"}, :status => 200
    end

    private

    def token_params
      params.require(:token).permit(:review, :movie_id, :user_id)
    end
  end
end
