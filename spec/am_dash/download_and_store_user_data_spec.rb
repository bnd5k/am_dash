require 'am_dash/download_and_store_user_data'

describe AMDash::DownloadAndStoreUserData do
  let(:account_summary) { double(:account_summary) }
  let(:events) { double(:events) }
  let(:weather_forecast) { double(:weather_forecast) }
  let(:news) { double(:news) }
  let(:user_id) { 4003 }

  subject { described_class.new(account_summary, events, weather_forecast, news) }

  it 'executes a whole bunuch of contexts' do
    [account_summary, events, weather_forecast].each do |context|
      expect(context).to receive(:execute).with(user_id)
    end
    expect(news).to receive(:execute)

    subject.execute(user_id)
  end

end
