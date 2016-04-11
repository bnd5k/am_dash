require 'am_dash/account/generate_events_list'

describe AMDash::Account::GenerateEventsList do
  let(:cache) { double(:cache) }
  let(:user_model) { double(:user_model) }
  let(:obtain_google_access_token) { AMDash::Account::ObtainGoogleAccessToken.new }
  let(:logger) { double(:logger, info: true) }
  let(:access_token) { 'asdf' }
  let(:mock_api_client) { double(:mock_api_client, authorization: authorization) }
  let(:authorization) { double(:authorization) }
  let(:service) { double(:service, events: events, settings: settings) }
  let(:events) { double(:events, list: 'list') }
  let(:settings) { double(:settings, list: 'list') }
  let(:user) { double(:user, id: 2000, email: "Austin@example.com") }
  let(:calendar_query_params) do
    {
      "calendarId" => user.email,
      "timeMin" => DateTime.now.in_time_zone("America/Los_Angeles").beginning_of_day.rfc3339,
      "timeMax" => DateTime.now.in_time_zone("America/Los_Angeles").end_of_day.rfc3339
    }
  end

  def calendar_query_response(status = "404", response = response_body)
    double(:calendar_query_response, status: status,  body: response)
  end

  let(:raw_start_date) { "2016-04-07T08:30:00-07:00" }
  let(:response_body) do
    "{\"kind\":\"calendar#events\",\"etag\":\"\\\"1459973109670000\\\"\",\"summary\":\"bd@alanrickman.com\",\"updated\":\"2016-04-06T20:05:09.670Z\",\"timeZone\":\"America/Los_Angeles\",\"accessRole\":\"owner\",\"defaultReminders\":[{\"method\":\"popup\",\"minutes\":10},{\"method\":\"email\",\"minutes\":10}],\"nextSyncToken\":\"CPDA1dTn-ssCEPDA1dTn-ssCGAU=\",\"items\":[{\"kind\":\"calendar#event\",\"etag\":\"\\\"2919579591736000\\\"\",\"id\":\"b6n2i2d8n59jmb3g7stbbvaprg\",\"status\":\"confirmed\",\"htmlLink\":\"https://www.google.com/calendar/event?eid=YjZuMmkyZDhuNTlqbWIzZzdzdGJidmFwcmcgYmRAYmVuZG93bmV5Lm5ldA\",\"created\":\"2016-04-04T17:09:55.000Z\",\"updated\":\"2016-04-04T17:09:55.868Z\",\"summary\":\"Marsh email re: charity checkin\",\"creator\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"organizer\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"start\":{\"dateTime\":\"#{raw_start_date}\"},\"end\":{\"dateTime\":\"2016-04-07T09:30:00-07:00\"},\"iCalUID\":\"b6n2i2d8n59jmb3g7stbbvaprg@google.com\",\"sequence\":0,\"hangoutLink\":\"https://plus.google.com/hangouts/_/alanrickman.com/bd?hceid=YmRAYmVuZG93bmV5Lm5ldA.b6n2i2d8n59jmb3g7stbbvaprg\",\"reminders\":{\"useDefault\":true}}]}"
  end
  let(:response_body_for_settings_request) do
"{\"kind\":\"calendar#settings\",\"etag\":\"\\\"1460246114871000\\\"\",\"nextSyncToken\":\"00001460246114871000\",\"items\":[{\"kind\":\"calendar#setting\",\"etag\":\"\\\"0\\\"\",\"id\":\"locale\",\"value\":\"en\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1406238629082000\\\"\",\"id\":\"format24HourTime\",\"value\":\"false\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1442340000000000\\\"\",\"id\":\"defaultEventLength\",\"value\":\"60\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1406238629082000\\\"\",\"id\":\"dateFieldOrder\",\"value\":\"MDY\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1442340000000000\\\"\",\"id\":\"remindOnRespondedEventsOnly\",\"value\":\"false\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"0\\\"\",\"id\":\"hideWeekends\",\"value\":\"false\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1406238629082000\\\"\",\"id\":\"weekStart\",\"value\":\"0\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1442340000000000\\\"\",\"id\":\"useKeyboardShortcuts\",\"value\":\"true\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"0\\\"\",\"id\":\"showDeclinedEvents\",\"value\":\"true\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"1429735685580000\\\"\",\"id\":\"timezone\",\"value\":\"America/Los_Angeles\"},{\"kind\":\"calendar#setting\",\"etag\":\"\\\"0\\\"\",\"id\":\"hideInvitations\",\"value\":\"false\"}]}"
  end

  subject { described_class.new(cache, user_model, obtain_google_access_token, logger) }

  before do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
    allow(Google::APIClient).to receive(:new).and_return(mock_api_client)
  end

  it 'returns empty array when unable to parse google response' do
    allow(obtain_google_access_token).to receive(:execute).with(user).and_return(access_token)

    expect(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).exactly(2).times.and_return(calendar_query_response)

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'returns empty array when it cannot obtain a google token' do
    allow(obtain_google_access_token).to receive(:execute).with(user).and_raise AMDash::Account::ObtainGoogleAccessToken::UnableToObtainGoogleAccessTokenError

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'grabs timezone for calendar from Google API' do
    allow(obtain_google_access_token).to receive(:execute).with(user).and_return(access_token)

    allow(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    expect(mock_api_client).to receive(:execute).with(
      :api_method => service.settings.list,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(
      calendar_query_response(200,response_body_for_settings_request)
    )

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response(200))


    allow(cache).to receive(:write)

    subject.execute(user.id)
  end

  it 'returns something even if when the API response is bad' do
    allow(obtain_google_access_token).to receive(:execute).with(user).and_return(access_token)

    expect(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.settings.list,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(
      calendar_query_response(200,response_body_for_settings_request)
    )

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response(404))

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'generate a list of events from Google Calendar data' do
    allow(obtain_google_access_token).to receive(:execute).with(user).and_return(access_token)

    expect(mock_api_client.authorization).to receive(:access_token=).with(access_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.settings.list,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(
      calendar_query_response(200,response_body_for_settings_request)
    )

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response(200))

    payload = [  { start: "8:30 AM", name: "Marsh email re: charity checkin" } ]

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
