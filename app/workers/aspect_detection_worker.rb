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
      $REDIS.setnx @movie_id, 1
      $REDIS.setnx "rv_#{@movie_id}", review
      $REDIS.setnx "sg_#{@movie_id}", f.aspect_hash.to_json
    else
      puts "Sidekiq: Movie found in REDIS."
      full_review = $REDIS.get "rv_#{@movie_id}"
      sentiment_groups = JSON.parse($REDIS.get "sg_#{@movie_id}")
    end

    # Send full review to Sentiment Analysis module.
    ReviewDispatcherWorker.perform_async(movie_id, review)

    # Send opinion sentences for each aspect to Sentiment Analysis module.
    sentiment_groups = f.aspect_hash if sentiment_groups.nil?

    sentiment_groups.each do |k, v|
      ReviewDispatcherWorker.perform_async(k.to_s, f.aspect_hash[k][:sentences])
    end

    $REDIS.quit
  end
end
