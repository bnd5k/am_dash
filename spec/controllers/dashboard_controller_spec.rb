require 'rails_helper'
require 'shared_contexts'

RSpec.describe DashboardController, type: :request do
  include_context "request authentication helper methods"
  include_context "global before and after hooks"

  let(:generate_account_summary) { double(:generate_account_summary) }
  let(:generate_events_list) { double(:generate_events_list) }
  let(:generate_weather_forecast) { double(:generate_weather_forecast) }
  let(:generate_recent_article_list) { double(:generate_recent_article_list) }
  let(:some_json) { {}.to_json }

  let(:user) do
    user = User.create!(
      first_name: "Aslak",
      email: "#{SecureRandom.base64(16)}@example.com", 
      password: SecureRandom.base64(16)
    )

    Location.create!(user_id: user.id, address: :home, category: 1, latitude: 100, longitude: 200)
    Location.create!(user_id: user.id, address: :work, category: 2, latitude: 300, longitude: 400)

    user
  end

  before do
    stub_const('ENV', {'AM_DASH_WORKER' => 'sucker_punch'})
    allow(AMDash::Account::GenerateAccountSummary).to receive(:new).and_return(generate_account_summary)
    allow(AMDash::Account::GenerateEventsList).to receive(:new).and_return(generate_events_list)
    allow(AMDash::Weather::GenerateWeatherForecast).to receive(:new).and_return(generate_weather_forecast)
    allow(AMDash::News::GenerateRecentArticlesList).to receive(:new).and_return(generate_recent_article_list)
  end

  it 'loads the dashboard' do
    sign_in user

    expect(generate_account_summary).to receive(:execute).with(any_args)
    expect(generate_events_list).to receive(:execute).with(user.id)
    expect(generate_weather_forecast).to receive(:execute).with(user.id)
    expect(generate_recent_article_list).to receive(:execute)

    expect(JSON).to receive(:parse).with(any_args).exactly(4).times.and_return({})

    get '/'
  end

end
