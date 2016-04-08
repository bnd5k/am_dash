require "rails"
require "am_dash/cache"

describe AMDash::Cache do
  let(:rails_cache_mock) { double(:rails_cache_mock) }

  before do
    allow(::Rails).to receive(:cache).and_return(rails_cache_mock)
  end

  it 'allows writing to a data store' do
    key = :foo
    payload = :bar
    expiration = 100

    expect(rails_cache_mock).to receive(:write).with(
      key,
      payload,
      expires_in: expiration
    )

    described_class.write(key, payload, expiration)
  end

  it 'allows reading from a data store' do
    key = :foo

    expect(rails_cache_mock).to receive(:read).with(key)

    described_class.read(key)
  end

end
