require 'am_dash/locations/create'

describe AMDash::Locations::Create do
  let(:location_model) { double(:location_model) }
  let(:user_id) { 1001 }
  let(:invalid_location) { double(:invalid_location, valid?: false) }
  let(:valid_location) { double(:valid_location, valid?: true, save!: true) }
  let(:home_address) { '123 Fake Street' }
  let(:work_address) { '456 Fake Street' }

  subject { described_class.new(location_model) }

  context "unable to save" do
    it 'does not attempt to save locations when user_id missing' do
      allow(location_model).to receive(:new).with(
          address: home_address,
          user_id: nil,
          category: described_class::LOCATION_CATEGORIES[:home]
      ).and_return(invalid_location)

      allow(location_model).to receive(:new).with(
          address: work_address,
          user_id: nil,
          category: described_class::LOCATION_CATEGORIES[:work]
      ).and_return(invalid_location)

      expect(subject.execute(home_address, work_address, nil)).to eq [invalid_location, invalid_location]
    end

    it 'returns handles an invalid locations' do
      allow(location_model).to receive(:new).with(
          address: home_address,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:home]
      ).and_return(valid_location)

      allow(location_model).to receive(:new).with(
          address: nil,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:work]
      ).and_return(invalid_location)

      expect(subject.execute(home_address, nil, user_id)).to eq [valid_location, invalid_location]
    end

    it 'returns handles multiple invalid locations' do
      allow(location_model).to receive(:new).with(
          address: nil,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:home]
      ).and_return(invalid_location)

      allow(location_model).to receive(:new).with(
          address: nil,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:work]
      ).and_return(invalid_location)

      expect(subject.execute(nil, nil, user_id)).to eq [invalid_location, invalid_location]
    end
  end

  context "records able to be saved" do
    it 'saves valid locations' do
      allow(location_model).to receive(:new).with(
          address: home_address,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:home]
      ).and_return(valid_location)

      allow(location_model).to receive(:new).with(
          address: work_address,
          user_id: user_id,
          category: described_class::LOCATION_CATEGORIES[:work]
      ).and_return(valid_location)

      expect(subject.execute(home_address, work_address, user_id)).to eq [valid_location, valid_location]
    end
  end

end
