class AspectDetectionWorker
  include Sidekiq::Worker

  def perform(*args)
    review = args.fetch(:review)
    movie_id = args.fetch(:movie_id)
    REDIS = Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')

    if REDIS.get movie_id.nil?
      t = Tokenizer.new(review, movie_id)
      FeatureIdentifier.new(t)
    else
      # Retrieve cached processed data and send back
    end
  end
end
