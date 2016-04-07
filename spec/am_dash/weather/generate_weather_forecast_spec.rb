require 'am_dash/weather/generate_weather_forecast'

describe AMDash::Weather::GenerateWeatherForecast do
  let(:user_model) { double(:user_model, find_by_id: nil) }
  let(:cache) { double(:cache) }
  let(:update_location_coordinates) { double(:update_location_coordinates) }
  let(:user) { double(:user, id: 2000, first_name: "Cora", locations: locations) }
  let(:locations) { double(:locations, home: home, work: work) }
  let(:home) { double(:home, address: 'asdf', latitude: -1232, longitude: 191) }
  let(:work) { double(:work, address: 'qewr', latitude: 987, longitude: -456) }
  let(:weather_query_response) { double(:weather_query_response, code: "200",  body: response_body) }
  let(:response_body) do
    "{\"list\":[{\"dt\":1460052000,\"main\":{\"temp\":65.53,\"temp_min\":63.86,\"temp_max\":65.53,\"pressure\":952.29,\"sea_level\":1034.49,\"grnd_level\":952.29,\"humidity\":70,\"temp_kf\":0.93},\"weather\":[{\"id\":800,\"main\":\"Clear\",\"description\":\"clear sky\",\"icon\":\"01d\"}],\"clouds\":{\"all\":0},\"wind\":{\"speed\":7.43,\"deg\":59.0032},\"sys\":{\"pod\":\"d\"},\"dt_txt\":\"2016-04-07 18:00:00\"},{\"dt\":1460062800,\"main\":{\"temp\":71.91,\"temp_min\":70.33,\"temp_max\":71.91,\"pressure\":950.72,\"sea_level\":1032.29,\"grnd_level\":950.72,\"humidity\":62,\"temp_kf\":0.88},\"weather\":[{\"id\":800,\"main\":\"Clear\",\"description\":\"clear sky\",\"icon\":\"01d\"}],\"clouds\":{\"all\":0},\"wind\":{\"speed\":7.4,\"deg\":78.5006},\"sys\":{\"pod\":\"d\"},\"dt_txt\":\"2016-04-07 21:00:00\"}]}" 
  end

  subject { described_class.new(user_model, cache, update_location_coordinates) }

  before do
    stub_const('ENV', {'AM_DASH_OPEN_WEATHER_KEY' => 'asdf'})
  end

  it 'fails gracefully' do
    expect(cache).to receive(:write).with(
      "#{user.id}-weather",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'ensures coordinates are present' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    expect(update_location_coordinates).to receive(:execute).with(user.id).and_return(
      [user.locations.home, user.locations.work]
    )


    allow(cache).to receive(:write)

    subject.execute(user.id)
  end

  it 'generates a forecast for the day' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(update_location_coordinates).to receive(:execute).with(user.id).and_return(
      [user.locations.home, user.locations.work]
    )

    uri = URI("http://api.openweathermap.org/data/2.5/forecast?lat=#{user.locations.home.latitude}&lon=#{user.locations.home.longitude}&units=imperial&appid=#{ENV["AM_DASH_OPEN_WEATHER_KEY"]}")

    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(weather_query_response)

    payload = [ { time: 1460052000, temp: 65.53 }, { time: 1460062800, temp: 71.91 } ]

    expect(cache).to receive(:write).with(
      "#{user.id}-weather",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
