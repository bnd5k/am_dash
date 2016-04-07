require 'rails_helper'
require 'am_dash/workers/sucker_punch/download_and_store_user_data'

describe AMDash::Worker::SuckerPunch::DownloadAndStoreUserData do
  let(:download_and_store_user_data) { double(:download_and_store_user_data) }

  subject { described_class.new }

  it 'executes a context' do
    user_id = 3001
    allow(AMDash).to receive(:download_and_store_user_data).and_return(download_and_store_user_data)
    expect(download_and_store_user_data).to receive(:execute).with(user_id)
    subject.perform(user_id)
  end
end
