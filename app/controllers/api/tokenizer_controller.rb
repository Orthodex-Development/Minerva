module Api
  class TokenizerController < ApplicationController
    wrap_parameters :token

    def tokenize
      # Send entire review to SA Module
      ReviewDispatcherWorker.perform_async("sa_rv_#{token_params[:movie_id]}", token_params[:review])
      # Send individual aspects for review
      AspectDetectionWorker.perform_async(token_params[:review], token_params[:movie_id])
      render :json => {:message => "received"}, :status => 200
    end

    private

    def token_params
      params.require(:token).permit(:review, :movie_id)
    end
  end
end
