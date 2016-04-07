require 'am_dash/account/update_location_coordinates'

describe AMDash::Account::UpdateLocationCoordinates do
  let(:coordinates_from_address) { double(:coordinates_from_address) }
  let(:user_model) { double(:user_model, find_by_id: nil) }
  let(:home_coordinates) { { latitude: -1232, longitude: 191 } }
  let(:work_coordinates) { { latitude: 987, longitude: -456 } }

  def mock_user(locations = locations_with_no_coordinates)
    double(:user, id: 2000, first_name: "Cora", locations: locations) 
  end

  def locations_with_no_coordinates
    home = location(:home, nil, nil)
    work = location(:work, nil, nil)
    double(:locations, home: home, work: work) 
  end

  def locations_with_existing_coordinates
    home = location(:home, home_coordinates[:latitude], home_coordinates[:longitude]) 
    work = location(:work, work_coordinates[:latitude], work_coordinates[:longitude]) 
    double(:locations, home: home, work: work) 
  end

  def locations_with_out_of_date_coordinates
    home = location(:home, -11111111111111, 5555555555555) 
    work = location(:work, 4444444444, 2222222222222) 
    double(:locations, home: home, work: work) 
  end

  def location(name, latitude, longitude)
    double(name, address: name, update_attributes: true, latitude: latitude, longitude: longitude) 
  end

  subject { described_class.new(user_model, coordinates_from_address) }

  it 'updates coordinates when they are not present' do
    user = mock_user

    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.home.address
    ).and_return(home_coordinates)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.work.address
    ).and_return(work_coordinates)

    expect(user.locations.home).to receive(:update_attributes).with(
      latitude: home_coordinates[:latitude],
      longitude: home_coordinates[:longitude]
    )

    expect(user.locations.work).to receive(:update_attributes).with(
      latitude: work_coordinates[:latitude],
      longitude: work_coordinates[:longitude]
    )

    expect(subject.execute(user.id)).to eq [user.locations.home, user.locations.work]
  end

  it 'does not update coordinates if they have not changed' do
    user = mock_user(locations_with_existing_coordinates)

    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.home.address
    ).and_return(home_coordinates)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.work.address
    ).and_return(work_coordinates)

    expect(user.locations.home).to_not receive(:update_attributes).with(any_args)

    expect(user.locations.work).to_not receive(:update_attributes).with(any_args)

    expect(subject.execute(user.id)).to eq [user.locations.home, user.locations.work]
  end

  it 'updates coordinates if they have changed' do
    user = mock_user(locations_with_out_of_date_coordinates)

    allow(user_model).to receive(:find_by_id).with(user.id).and_return(user)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.home.address
    ).and_return(home_coordinates)

    allow(coordinates_from_address).to receive(:execute).with(
      user.locations.work.address
    ).and_return(work_coordinates)

    expect(user.locations.home).to receive(:update_attributes).with(
      latitude: home_coordinates[:latitude],
      longitude: home_coordinates[:longitude]
    )

    expect(user.locations.work).to receive(:update_attributes).with(
      latitude: work_coordinates[:latitude],
      longitude: work_coordinates[:longitude]
    )

    expect(subject.execute(user.id)).to eq [user.locations.home, user.locations.work]
  end

end
