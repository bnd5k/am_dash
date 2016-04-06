require "rails"
require "am_dash/cache"

describe AMDash::Cache do
  let(:rails_cache_mock) { double(:rails_cache_mock) }

  before do
    allow(::Rails).to receive(:cache).and_return(rails_cache_mock)
  end

  it 'wraps the behavior of the true cachier' do
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

end
