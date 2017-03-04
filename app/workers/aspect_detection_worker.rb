class AspectDetectionWorker
  include Sidekiq::Worker

  def perform(*args)
    review = args.fetch(:review)
    movie_id = args.fetch(:movie_id)

    REDIS = Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
    result = REDIS.get movie_id

    if result.nil?
      t = Tokenizer.new(review)
      f = FeatureIdentifier.new(t)
      REDIS.setnx movie_id f.aspect_hash.to_json
    else
      sentiment_groups = JSON.parse(REDIS.get movie_id)
    end
    REDIS.quit
  end
end
