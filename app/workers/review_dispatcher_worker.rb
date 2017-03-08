class ReviewDispatcherWorker
  include Sidekiq::Worker

  def perform(label, review_part, key = nil)
    $REDIS = Redis.new(url: ENV["REDISCLOUD_URL"] || 'redis://localhost:6379/14')

    review = review_part
    response = HTTParty.post(Rails.application.secrets.SA_DOMAIN + "sentiment",
      :body => {
          :review => review_part,
        }.to_json,

      :headers => { 'Content-Type' => 'application/json' })

    Rails.logger.info "ReviewDispatcherWorker: response code = #{response.code}"

    if response.code == 200
      sentiment = response.parsed_response
      if key.nil?
        # Full movie review sentiment
        puts "ReviewDispatcherWorker: Storing in REDIS with key : #{label} and value: #{sentiment.to_json}"
        $REDIS.setnx label, sentiment.to_json
      else
        # Movie aspect sentiment
        "ReviewDispatcherWorker: Storing in REDIS with key : #{label} and value: #{sentiment.to_json}"
        $REDIS.hset label, key, sentiment.to_json
      end
    else
      puts "ReviewDispatcherWorker: Error: HTTP call returned code #{response.code}"
    end

    $REDIS.quit
  end
end
