require 'am_dash/weather/generate_weather_forecast'

describe AMDash::Weather::GenerateWeatherForecast do
  let(:user_model) { double(:user_model, find_by_id: nil) }
  let(:cache) { double(:cache) }
  let(:update_location_coordinates) { double(:update_location_coordinates) }
  let(:user) { double(:user, id: 2000, first_name: "Cora", locations: locations) }
  let(:locations) { double(:locations, home: home, work: work) }
  let(:home) { double(:home, address: 'asdf', latitude: -1232, longitude: 191) }
  let(:work) { double(:work, address: 'qewr', latitude: 987, longitude: -456) }
  let(:user_locations) { [user.locations.home, user.locations.work] }
  let(:bad_weather_query_response) { double(:bad_weather_query_response, code: "401") }
  let(:weather_query_response) { double(:weather_query_response, code: "200",  body: response_body) }
  let(:response_body) do
    "{\"hourly\":{\"data\":[{\"time\":1460012400,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":46.55,\"apparentTemperature\":46.55,\"dewPoint\":37.29,\"humidity\":0.7,\"windSpeed\":0.45,\"windBearing\":78,\"visibility\":9.96,\"cloudCover\":0.05,\"pressure\":1025.12,\"ozone\":301.33},{\"time\":1460034000,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":44.43,\"apparentTemperature\":44.43,\"dewPoint\":36.75,\"humidity\":0.74,\"windSpeed\":0.85,\"windBearing\":104,\"visibility\":9.84,\"cloudCover\":0.05,\"pressure\":1025.48,\"ozone\":301.61},{\"time\":1460044800,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":43.41,\"apparentTemperature\":43.41,\"dewPoint\":36.88,\"humidity\":0.78,\"windSpeed\":1.01,\"windBearing\":98,\"visibility\":9.88,\"cloudCover\":0.02,\"pressure\":1025.52,\"ozone\":301.89},{\"time\":1460055600,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":43.17,\"apparentTemperature\":43.17,\"dewPoint\":37.84,\"humidity\":0.81,\"windSpeed\":1.99,\"windBearing\":84,\"visibility\":9.87,\"cloudCover\":0.07,\"pressure\":1025.29,\"ozone\":302.01},{\"time\":1460066400,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":41.56,\"apparentTemperature\":41.56,\"dewPoint\":37.26,\"humidity\":0.85,\"windSpeed\":1.88,\"windBearing\":64,\"visibility\":9.87,\"cloudCover\":0.08,\"pressure\":1024.98,\"ozone\":302.04},{\"time\":1460077200,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":39.67,\"apparentTemperature\":39.67,\"dewPoint\":36.02,\"humidity\":0.87,\"windSpeed\":2.31,\"windBearing\":71,\"visibility\":9.86,\"cloudCover\":0.11,\"pressure\":1024.88,\"ozone\":301.99},{\"time\":1460088000,\"summary\":\"Clear\",\"icon\":\"clear-night\",\"precipIntensity\":0,\"precipProbability\":0,\"temperature\":39.67,\"apparentTemperature\":39.67,\"dewPoint\":36.02,\"humidity\":0.87,\"windSpeed\":2.31,\"windBearing\":71,\"visibility\":9.86,\"cloudCover\":0.11,\"pressure\":1024.88,\"ozone\":301.99}]}}"
  end
  let(:mock_time) { 1460086262 }

  subject { described_class.new(user_model, cache, update_location_coordinates) }

  before do
    stub_const('ENV', {'AM_DASH_OPEN_WEATHER_KEY' => 'asdf'})
    allow(Time).to receive(:now).and_return(mock_time)
  end

  it 'fails gracefully' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
    allow(update_location_coordinates).to receive(:execute).and_return(user_locations)

    allow(Net::HTTP).to receive(:get_response).and_return(bad_weather_query_response)
    
    expect(cache).to receive(:write).with(
      "#{user.id}-weather",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'ensures coordinates are present' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(Net::HTTP).to receive(:get_response).and_return(weather_query_response)

    expect(update_location_coordinates).to receive(:execute).with(
      user.id
    ).and_return(user_locations)

    allow(cache).to receive(:write)

    subject.execute(user.id)
  end

  it 'generates a forecast for the day' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(update_location_coordinates).to receive(:execute).with(
      user.id
    ).and_return(user_locations)

    uri  = URI("https://api.forecast.io/forecast/#{ENV["AM_DASH_FORECAST_IO_KEY"]}/#{user.locations.home.latitude},#{user.locations.home.longitude},#{Time.now.to_i}")

    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(weather_query_response)

    payload = [
      { time: 6, temp: 44.43 },
      { time: 9, temp: 43.41 },
      { time: 12, temp: 43.17 },
      { time: 15, temp: 41.56 },
      { time: 18, temp: 39.67 },
      { time: 21, temp: 39.67 },
    ]

    expect(cache).to receive(:write).with(
      "#{user.id}-weather",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
