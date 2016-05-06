require 'am_dash/account/generate_events_list'

describe AMDash::Account::GenerateEventsList do
  let(:cache) { double(:cache, write: true) }
  let(:user_model) { double(:user_model) }
  let(:logger) { double(:logger, info: true) }
  let(:calendar_service) { double(:calendar_service) }
  let(:user) { double(:user, id: 2000, email: "Austin@example.com") }
  let(:timezone_payload) { [{ "id" => "timezone", "value" => timezone } ] }
  let(:timezone) { "America/Los_Angeles" }
  let(:events_payload) { [ event ] }
  let(:event) do
    { 
        "summary" => "Marsh email re: charity checkin",
        "start" => { "dateTime"=>"2016-04-07T08:30:00-07:00" }
    } 
  end

  subject { described_class.new(cache, user_model, logger, calendar_service) }

  before do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
  end

  it 'grabs calendar timezone and events from Google API' do
    allow(calendar_service).to receive(:timezone_request).with(user.id).and_return(timezone_payload)

    allow(calendar_service).to receive(:calendar_events_list).with(
      user.id,
      user.email,
      "Pacific Time (US & Canada)"
    ).and_return(events_payload)

    expected_start = DateTime.parse(event["start"]["dateTime"]).strftime("%l:%M %p").strip

    payload = [  { start: expected_start, name: event["summary"] } ]

    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'uses default timezone if unable to retrieve timezone from Google' do
    allow(calendar_service).to receive(:timezone_request).with(user.id).and_return(nil)

    expect(calendar_service).to receive(:calendar_events_list).with(
      user.id,
      user.email,
      "Eastern Time (US & Canada)" 
    ).and_return(events_payload)

    subject.execute(user.id)
  end

  it 'caches empty array if unable to grab calendar events' do
    allow(calendar_service).to receive(:timezone_request).with(user.id).and_return(timezone_payload)

    allow(calendar_service).to receive(:calendar_events_list).with(
      user.id,
      user.email,
      "Pacific Time (US & Canada)"
    ).and_return([])
    
    expect(cache).to receive(:write).with(
      "#{user.id}-events",
      [].to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
