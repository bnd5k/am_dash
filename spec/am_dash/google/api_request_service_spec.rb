require 'am_dash/google/api_request_service'

describe AMDash::Google::APIRequestService do
  let(:obtain_google_access_token) { double(:obtain_google_access_token) }
  let(:logger) { double(:logger, info: true) }
  let(:timezone) { "America/Los_Angeles" }
  let(:access_token) { 'asdf' }
  let(:mock_api_client) { double(:mock_api_client, authorization: authorization) }
  let(:authorization) { double(:authorization) }
  let(:service) { double(:service, events: events, settings: settings) }
  let(:events) { double(:events, list: 'list') }
  let(:settings) { double(:settings, list: 'list') }
  let(:email) { 'asdf@example.com' }
  let(:user_id) { 123 }

  let(:raw_start_date) { "2016-04-07T08:30:00-07:00" }
  let(:calendar_query_params) do
    {
      "calendarId" => email,
      "timeMin" => DateTime.now.in_time_zone(timezone).beginning_of_day.strftime("%FT%T%z"),
      "timeMax" => DateTime.now.in_time_zone(timezone).end_of_day.strftime("%FT%T%z")
    }
  end

  def calendar_query_response(status = "404", response = response_body)
    double(:calendar_query_response, status: status,  body: response)
  end
  let(:response_body) do
    "{\"kind\":\"calendar#events\",\"etag\":\"\\\"1459973109670000\\\"\",\"summary\":\"bd@alanrickman.com\",\"updated\":\"2016-04-06T20:05:09.670Z\",\"timeZone\":\"America/Los_Angeles\",\"accessRole\":\"owner\",\"defaultReminders\":[{\"method\":\"popup\",\"minutes\":10},{\"method\":\"email\",\"minutes\":10}],\"nextSyncToken\":\"CPDA1dTn-ssCEPDA1dTn-ssCGAU=\",\"items\":[{\"kind\":\"calendar#event\",\"etag\":\"\\\"2919579591736000\\\"\",\"id\":\"b6n2i2d8n59jmb3g7stbbvaprg\",\"status\":\"confirmed\",\"htmlLink\":\"https://www.google.com/calendar/event?eid=YjZuMmkyZDhuNTlqbWIzZzdzdGJidmFwcmcgYmRAYmVuZG93bmV5Lm5ldA\",\"created\":\"2016-04-04T17:09:55.000Z\",\"updated\":\"2016-04-04T17:09:55.868Z\",\"summary\":\"Marsh email re: charity checkin\",\"creator\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"organizer\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"start\":{\"dateTime\":\"#{raw_start_date}\"},\"end\":{\"dateTime\":\"2016-04-07T09:30:00-07:00\"},\"iCalUID\":\"b6n2i2d8n59jmb3g7stbbvaprg@google.com\",\"sequence\":0,\"hangoutLink\":\"https://plus.google.com/hangouts/_/alanrickman.com/bd?hceid=YmRAYmVuZG93bmV5Lm5ldA.b6n2i2d8n59jmb3g7stbbvaprg\",\"reminders\":{\"useDefault\":true}}]}"
  end
  
  subject { described_class.new(obtain_google_access_token, logger) }

  before do
    allow(Google::APIClient).to receive(:new).and_return(mock_api_client)
  end

  it 'returns empty array when it cannot obtain a google token' do
    allow(obtain_google_access_token).to receive(:execute).with(user_id).and_raise AMDash::Google::ObtainGoogleAccessToken::UnableToObtainGoogleAccessTokenError

    expect(
      subject.calendar_events_list(user_id, email, timezone)
    ).to be_empty
  end

  it 'returns empty array when unable to parse google response' do
    allow(obtain_google_access_token).to receive(:execute).with(user_id).and_return(access_token)

    expect(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).exactly(2).times.and_return(calendar_query_response)

    expect(
      subject.calendar_events_list(user_id, email, timezone)
    ).to be_empty
  end

  it 'returns array of events' do

    allow(obtain_google_access_token).to receive(:execute).with(user_id).and_return(access_token)

    allow(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response(200))

    expected_result =  JSON.parse(response_body)["items"]

    expect(
      subject.calendar_events_list(user_id, email, timezone)
    ).to eq expected_result

  end
end
