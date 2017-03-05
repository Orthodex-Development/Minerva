class AspectDetectionWorker
  include Sidekiq::Worker

  def perform(review, movie_id)
    puts "Sidekiq: Received movie_id : #{movie_id}"
    @movie_id = movie_id

    $REDIS = Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
    result = $REDIS.get @movie_id

    if result.nil?
      puts "Sidekiq: Movie not stored in REDIS, running opinion mining and feature extraction."
      t = Tokenizer.new(review)
      f = FeatureIdentifier.new(t)
      $REDIS.setnx @movie_id, f.aspect_hash.to_json
    else
      puts "Sidekiq: Movie found in REDIS."
      sentiment_groups = JSON.parse($REDIS.get @movie_id)
    end
    $REDIS.quit
  end
end
