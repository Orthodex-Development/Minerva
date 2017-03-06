class ReviewDispatcherWorker
  include Sidekiq::Worker

  def perform(label, review_part)
    review = review_part
    response = HTTParty.post(Rails.secrets.SA_DOMAIN,
      :body => {
          :review => review_part,
          :label => label
        }.to_json,

      :headers => { 'Content-Type' => 'application/json' })

    Rails.logger.info "ReviewDispatcherWorker: response code = #{response.code}"
  end
end
