class AspectDetectionWorker
  include Sidekiq::Worker

  def perform(*args)
    review = args.fetch(:review)
    # TODO: Break review into paragraphs, detect aspects from paragraph.
  end
end
