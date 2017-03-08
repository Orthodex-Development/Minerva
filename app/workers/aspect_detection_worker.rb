class AspectDetectionWorker
  include Sidekiq::Worker

  def perform(review, movie_id, user)
    $REDIS ||= Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
    puts "Sidekiq: Received movie_id : #{movie_id}"
    @movie_id = movie_id

    result = $REDIS.get @movie_id

    if result.nil?
      puts "Sidekiq: Movie not stored in REDIS, running opinion mining and feature extraction."

      puts "Sidekiq: Sending full review for Sentiment Analysis."
      # Send entire review to SA Module
      ReviewDispatcherWorker.perform_async("sa_rv_#{movie_id}", review)

      t = Tokenizer.new(review)
      f = FeatureIdentifier.new(t)
      $REDIS.setnx "#{@movie_id}", 1
      $REDIS.setnx "rv_#{@movie_id}", review
      $REDIS.setnx "sg_#{@movie_id}", f.aspect_hash.to_json

      # Send opinion sentences for each aspect to Sentiment Analysis module.
      sentiment_groups = f.aspect_hash

      batch = Sidekiq::Batch.new
      batch.description = "Batch of Workers retrieving sentiment behind each aspect of a movie."
      batch.on(:success, 'ResultDispatchWorker#perform_async', { :id => movie_id, :user => user })
      batch.jobs do
        sentiment_groups.each do |k, v|
          ReviewDispatcherWorker.perform_async("sa_sg_#{movie_id}", f.aspect_hash[k][:sentences], k)
        end
      end
      puts "Just started Sidekiq Batch #{batch.bid}"

    else
      puts "AspectDetectionWorker: Movie found in REDIS. Running ResultDispatchWorker"

      ResultDispatchWorker.perform_async(movie_id, user)
    end
    $REDIS.quit
  end
end
