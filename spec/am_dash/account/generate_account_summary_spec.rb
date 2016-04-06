require 'am_dash/account/generate_account_summary'

describe AMDash::Account::GenerateAccountSummary do
  let(:user_model) { double(:user_model, find_by_id: nil) }
  let(:user) { double(:user, id: 2000, first_name: "Cora", locations: locations) }
  let(:locations) { double(:locations, home: home, work: work) }
  let(:home) { double(:home, address: 'asdf', update_attributes: true) }
  let(:work) { double(:work, address: 'qewr', update_attributes: true) }
  let(:home_coordinates) { { latitude: -1232, longitude: 191 } }
  let(:work_coordinates) { { latitude: 987, longitude: -456 } }

  let(:cache) { double(:cache) }
  let(:coordinates_from_address) { double(:coordinates_from_address) }

  subject { described_class.new(user_model, cache, coordinates_from_address) }

  it 'fails gracefully' do
    expect(cache).to receive(:write).with(
      "#{user.id}-account",
      {}.to_json,
      described_class::FOUR_HOURS
    )
    subject.execute(user.id)
  end

  it 'generates an object with partial collection of attributes' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
    allow(coordinates_from_address).to receive(:execute).and_return(nil)

    payload = {
      first_name: user.first_name
    }

    expect(cache).to receive(:write).with(
      "#{user.id}-account",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it 'generates an object with all attributes' do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)
    
    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.home.address
    ).and_return(home_coordinates)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.work.address
    ).and_return(work_coordinates)

    payload = {
      first_name: user.first_name,
      home_latitude: home_coordinates[:latitude],
      home_longitude: home_coordinates[:longitude],
      work_latitude: work_coordinates[:latitude],
      work_longitude: work_coordinates[:longitude],
    }

    expect(cache).to receive(:write).with(
      "#{user.id}-account",
      payload.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute(user.id)
  end

  it "updates locations" do
    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.home.address
    ).and_return(home_coordinates)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.work.address
    ).and_return(work_coordinates)

    allow(cache).to receive(:write)

    expect(user.locations.home).to receive(:update_attributes).with(
      latitude: home_coordinates[:latitude],
      longitude: home_coordinates[:longitude]
    )

    expect(user.locations.work).to receive(:update_attributes).with(
      latitude: work_coordinates[:latitude],
      longitude: work_coordinates[:longitude]
    )
      
    subject.execute(user.id)
  end

end
