require 'am_dash/account/generate_events_list'

describe AMDash::Account::GenerateEventsList do
  let(:cache) { double(:cache) }
  let(:user_model) { double(:user_model) }
  let(:mock_api_client) { double(:mock_api_client, authorization: authorization) }
  let(:authorization) { double(:authorization) }
  let(:service) { double(:service, events: events) }
  let(:events) { double(:events, list: 'list') }
  let(:user) { double(:user, id: 2000, email: "Austin@example.com", google_token: 'cool-token') }
  let(:calendar_query_params) do
    {
      "calendarId" => user.email,
      "timeMin" => DateTime.now.utc.beginning_of_day.rfc3339,
      "timeMax" => DateTime.now.utc.end_of_day.rfc3339
    }
  end

  def calendar_query_response(status = "404")
    double(:calendar_query_response, status: status,  body: response_body)
  end

  let(:response_body) do
    "{\"kind\":\"calendar#events\",\"etag\":\"\\\"1459973109670000\\\"\",\"summary\":\"bd@alanrickman.com\",\"updated\":\"2016-04-06T20:05:09.670Z\",\"timeZone\":\"America/Los_Angeles\",\"accessRole\":\"owner\",\"defaultReminders\":[{\"method\":\"popup\",\"minutes\":10},{\"method\":\"email\",\"minutes\":10}],\"nextSyncToken\":\"CPDA1dTn-ssCEPDA1dTn-ssCGAU=\",\"items\":[{\"kind\":\"calendar#event\",\"etag\":\"\\\"2919579591736000\\\"\",\"id\":\"b6n2i2d8n59jmb3g7stbbvaprg\",\"status\":\"confirmed\",\"htmlLink\":\"https://www.google.com/calendar/event?eid=YjZuMmkyZDhuNTlqbWIzZzdzdGJidmFwcmcgYmRAYmVuZG93bmV5Lm5ldA\",\"created\":\"2016-04-04T17:09:55.000Z\",\"updated\":\"2016-04-04T17:09:55.868Z\",\"summary\":\"Marsh email re: charity checkin\",\"creator\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"organizer\":{\"email\":\"bd@alanrickman.com\",\"displayName\":\"Alan Rickman\",\"self\":true},\"start\":{\"dateTime\":\"2016-04-07T08:30:00-07:00\"},\"end\":{\"dateTime\":\"2016-04-07T09:30:00-07:00\"},\"iCalUID\":\"b6n2i2d8n59jmb3g7stbbvaprg@google.com\",\"sequence\":0,\"hangoutLink\":\"https://plus.google.com/hangouts/_/alanrickman.com/bd?hceid=YmRAYmVuZG93bmV5Lm5ldA.b6n2i2d8n59jmb3g7stbbvaprg\",\"reminders\":{\"useDefault\":true}}]}"
  end

  subject { described_class.new(cache, user_model) }

  before do
    allow(Google::APIClient).to receive(:new).and_return(mock_api_client)
  end

  it 'fails gracefully' do

    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    expect(mock_api_client.authorization).to receive(:access_token=).with(user.google_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response)

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'generate a list of events from Google Calendar data' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    expect(mock_api_client.authorization).to receive(:access_token=).with(user.google_token)

    allow(mock_api_client).to receive(:discovered_api).with('calendar', 'v3').and_return(service)

    allow(mock_api_client).to receive(:execute).with(
      :api_method => service.events.list,
      :parameters => calendar_query_params,
      :headers => {'Content-Type' => 'application/json'}
    ).and_return(calendar_query_response("200"))

    payload = [  
      { start: "2016-04-07T08:30:00-07:00", name: "Marsh email re: charity checkin" }
    ]

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
