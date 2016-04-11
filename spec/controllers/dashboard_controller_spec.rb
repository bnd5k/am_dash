require 'rails_helper'
require 'shared_contexts'

RSpec.describe DashboardController, type: :request do
  include_context "request authentication helper methods"
  include_context "global before and after hooks"

  let(:generate_account_summary) { double(:generate_account_summary) }
  let(:generate_events_list) { double(:generate_events_list) }
  let(:generate_weather_forecast) { double(:generate_weather_forecast) }
  let(:generate_recent_article_list) { double(:generate_recent_article_list) }

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

  describe "GET index" do
    context 'dashboard data not present' do
      it 'generates the dashboard data the dashboard' do
        sign_in user

        expect(generate_account_summary).to receive(:execute).with(user.id)
        expect(generate_events_list).to receive(:execute).with(user.id)
        expect(generate_weather_forecast).to receive(:execute).with(user.id)
        expect(generate_recent_article_list).to receive(:execute)

        # expect(JSON).to receive(:parse).with(any_args).exactly(4).times.and_return({})

        get '/'
        expect(response.code).to eq "302"
      end
    end

    context 'dashboard data present' do
      let(:account) { { "name" => "Joes" }.to_json }
      let(:weather) { [ { "temp" => "70" }].to_json }
      let(:events) { [ { "start" => "12:00pm", "name" => "lunch"} ].to_json }
      let(:news) { [ { "headline" => "bad", "snippet" => "even worse", "url" => "nyt.com" } ].to_json }

      it 'loads the data from the cache store' do
        sign_in user

        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-account"
        ).and_return(account)
        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-weather"
        ).and_return(weather)
        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-events"
        ).and_return(events)
        allow(AMDash::Cache).to receive(:read).with(
          "news"
        ).and_return(news)

        get '/'

        expect(response.code).to eq "200"
      end
    end

    context 'dashboard data present but empty' do
      let(:empty_array) { [].to_json }
      let(:empty_hash) { {}.to_json }

      it 'loads the data from the cache store' do
        sign_in user

        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-account"
        ).and_return(empty_hash)
        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-weather"
        ).and_return(empty_array)
        allow(AMDash::Cache).to receive(:read).with(
          "#{user.id}-events"
        ).and_return(empty_array)
        allow(AMDash::Cache).to receive(:read).with(
          "news"
        ).and_return(empty_array)

        get '/'

        expect(response.code).to eq "200"
      end
    end
  end

end
