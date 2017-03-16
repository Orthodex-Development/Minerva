class ResultDispatchWorker
  include Sidekiq::Worker

  def perform(movie_id, user)
    $REDIS ||= Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')
    sentiment_groups = JSON.parse($REDIS.get "sg_#{movie_id}")

    movie_aspect_sentiment = {}

    sentiment_groups.each do |k, v|
      movie_aspect_sentiment[k] = JSON.parse($REDIS.hget "sa_sg_#{movie_id}", k.to_s)
    end

    results = ""

    movie_aspect_sentiment.each do |k, v|
      results << k.to_s + " => " + ResultDispatchWorker.get_label(v) + "\n"
    end

    full_sentiment = ResultDispatchWorker.get_label(JSON.parse($REDIS.get "sa_rv_#{movie_id}"))

    results = "Here are the results:\nOverall sentiment: #{full_sentiment}\n" + results
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
        return "(y)"
      elsif params["score"].between? 1.2, 1.7
        return "(y) (y)"
      elsif params["score"].between? 1.7, 2.7
        return "(y) (y) (y)"
      elsif params["score"].between? 2.7, 3.3
        return "(y) (y) (y) (y)"
      elsif params["score"] > 3.3
        return "(y) (y) (y) (y)"
      end
    when "neg"
      if params["score"] < 0
        return "no strong sentiment"
      elsif params["score"].between? 0, 1.2
        return "👎"
      elsif params["score"].between? 1.2, 1.7
        return "👎👎"
      elsif params["score"].between? 1.7, 2,7
        return "👎👎👎"
      elsif params["score"].between? 2.7, 3.3
        return "👎👎👎👎"
      elsif params["score"] > 3.3
        return "👎👎👎👎👎"
      end
    end
  end
end
