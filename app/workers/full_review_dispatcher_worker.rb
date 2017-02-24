class FullReviewDispatcherWorker
  include Sidekiq::Worker

  def perform(*args)
    review = args.fetch(:review)
    # TODO: send to python endpoint
    # HTTParty.post()
  end
end
