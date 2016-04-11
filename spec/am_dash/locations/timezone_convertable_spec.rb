require 'am_dash/locations/timezone_convertable'

class DummyClass
  include AMDash::Locations::TimezoneConvertable
end

describe DummyClass do

  subject { described_class.new }

  it 'accomodates nil inputs' do
    expect(subject.google_to_rails_timezone_name(nil)).to be_nil
  end

  it 'accomodates empty strings' do
    expect(subject.google_to_rails_timezone_name("")).to be_nil
  end

  it "converts Google's PST timezone to Rails' PST timezone" do
    {
      "America/Los_Angeles" => "Pacific Time (US & Canada)",
      "America/Denver" => "Mountain Time (US & Canada)",
      "America/Chicago" => "Central Time (US & Canada)",
      "America/New_York" => "Eastern Time (US & Canada)" 
    }.each do |google_name, rails_name|

      expect(
        subject.google_to_rails_timezone_name(google_name)
      ).to eq rails_name
    end
  end

end
