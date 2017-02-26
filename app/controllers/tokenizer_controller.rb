class TokenizerController < ApplicationController
  def tokenize
    # Send entire review to SA Module
    FullReviewDispatcherWorker.perform_async(token_params)
    AspectDetectionWorker.perform_async(token_params)
    render :json => {:message => "recieved"}, :status => 200
  end

  private

  def token_params
    params.require(:token).permit(:review, :movie_id)
  end
end
