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
      results << k.to_s + " => " + ResultDispatchWorker.get_label(v) + "\n "
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

  def self.get_label(params)
    case params["label"]
    when "pos" then
      if params["score"] < 0
        return "no strong sentiment"
      elsif params["score"].between? 0, 1.2
        return "1 like"
      elsif params["score"].between? 1.2, 1.7
        return "2 likes"
      elsif params["score"].between? 1.7, 2.7
        return "3 likes"
      elsif params["score"].between? 2.7, 3.3
        return "4 likes"
      elsif params["score"] > 3.3
        return "5 likes"
      end
    when "neg"
      if params["score"] < 0
        return "no strong sentiment"
      elsif params["score"].between? 0, 1.2
        return "1 dislike"
      elsif params["score"].between? 1.2, 1.7
        return "2 dislikes"
      elsif params["score"].between? 1.7, 2,7
        return "3 dislikes"
      elsif params["score"].between? 2.7, 3.3
        return "4 dislikes"
      elsif params["score"] > 3.3
        return "5 dislikes"
      end
    end
  end
end
