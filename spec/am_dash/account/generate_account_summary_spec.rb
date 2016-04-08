require 'am_dash/account/generate_account_summary'

describe AMDash::Account::GenerateAccountSummary do
  let(:user_model) { double(:user_model, find_by_id: nil) }
  let(:cache) { double(:cache) }
  let(:update_location_coordinates) { double(:update_location_coordinates) }
  let(:user) { double(:user, id: 2000, first_name: "Cora", locations: locations) }
  let(:locations) { double(:locations, home: home, work: work) }
  let(:home) { double(:home, address: 'asdf', latitude: -1232, longitude: 191) }
  let(:work) { double(:work, address: 'qewr', latitude: 987, longitude: -456) }

  subject { described_class.new(user_model, cache, update_location_coordinates) }

  it 'fails gracefully' do
    expect(cache).to receive(:write).with(
      "#{user.id}-account",
      {}.to_json,
      described_class::FOUR_HOURS
    )
    subject.execute(user.id)
  end

  it 'generates an object with expected attributes' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
    
    allow(update_location_coordinates).to receive(:execute).with(
      user.id
    ).and_return([user.locations.home, user.locations.work])

    payload = {
      first_name: user.first_name,
      home_latitude: user.locations.home.latitude,
      home_longitude: user.locations.home.longitude,
      work_latitude: user.locations.work.latitude,
      work_longitude: user.locations.work.longitude
    }

    expect(cache).to receive(:write).with(
      "#{user.id}-account",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

end
