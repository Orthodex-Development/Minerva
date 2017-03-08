class ResultDispatchWorker
  include Sidekiq::Worker

  def perform(id, user)
    $REDIS ||= Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
    sentiment_groups = JSON.parse($REDIS.get "sg_#{id}")

    movie_aspect_sentiment = {}

    sentiment_groups.each do |k, v|
      movie_aspect_sentiment[k] = JSON.parse($REDIS.hget "sa_sg_#{id}", k.to_s)
    end

    results = ""

    movie_aspect_sentiment.each do |k, v|
      results << k.to_s + " => " + v.to_s + "\n "
    end

    results = "Here are the results:\n " + results

    response = HTTParty.post(Rails.application.secrets.BOT_ENDPOINT + "analysis",
      :body => {
          :message => results,
          :user => user
        }.to_json,

      :headers => { 'Content-Type' => 'application/json' })

    $REDIS.quit
  end
end
