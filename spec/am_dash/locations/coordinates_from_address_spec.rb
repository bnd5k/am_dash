require 'am_dash/locations/coordinates_from_address'

describe AMDash::Locations::CoordinatesFromAddress do
  let(:geocoder) { double(:geocoder, search: []) }
  let(:query_results) { [ double(:query_results, coordinates: [lat, long]) ] }
  let(:address) { "123 Fake Street, Columbus OH" }
  let(:lat) { 1000 }
  let(:long) { 2000 }

  subject { described_class.new(geocoder) }

  it 'fails gracefully' do
    expect(subject.execute(nil)).to be_nil
  end

  it 'handles unknown addresses' do
    allow(geocoder).to receive(:search).with(address).and_return([])

    expect(subject.execute(nil)).to be_nil
  end

  it 'parses geolocation from a string' do
    allow(geocoder).to receive(:search).with(address).and_return(query_results)
    expected_result = { latitude: lat, longitude: long }

    expect(subject.execute(address)).to eq expected_result
  end

end
