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
      $REDIS.setnx "#{@movie_id}", 1
      $REDIS.setnx "rv_#{@movie_id}", review
      $REDIS.setnx "sg_#{@movie_id}", f.aspect_hash.to_json

      # Send opinion sentences for each aspect to Sentiment Analysis module.
      sentiment_groups = f.aspect_hash

      sentiment_groups.each do |k, v|
        ReviewDispatcherWorker.perform_async("sa_sg_#{movie_id}", f.aspect_hash[k][:sentences], k)
      end

    else
      puts "Sidekiq: Movie found in REDIS. Retrieving sentiments..."

      full_movie_sentiment = JSON.parse($REDIS.get "sa_rv_#{movie_id}")
      sentiment_groups = JSON.parse($REDIS.get "sg_#{@movie_id}")

      movie_aspect_sentiment = {}

      sentiment_groups.each do |k, v|
        movie_aspect_sentiment[k] = JSON.parse($REDIS.hget "sa_sg_#{movie_id}", k.to_s)
      end

      puts "Movie Sentiment: #{full_movie_sentiment}"
      puts "Movie Aspects Sentiment: #{movie_aspect_sentiment}"
    end
    $REDIS.quit
  end
end
