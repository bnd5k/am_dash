require 'rails_helper'
require 'am_dash/worker'

describe AMDash::Worker do
  let(:job) { double(:job) }
  
  subject { described_class }

  context "sucker punch worker" do

    before { stub_const('ENV', {'AM_DASH_WORKER' => 'sucker_punch'}) }
    it "enqueues job to download and story user data" do
      user_id = 5008

      expect(AMDash::Worker::SuckerPunch::DownloadAndStoreUserData).to receive(:perform_async).with(user_id) 

      subject.enqueue(:download_and_store_user_data, user_id)
    end

    it "raises an error when job_name not recognized" do
      expect{ subject.enqueue(:some_job) }.to raise_error described_class::NoJobFoundError
    end
  end

  context "no worker" do
    before { stub_const('ENV', {'AM_DASH_WORKER' => ''}) }

    it "barfs when there is no worker environment variable" do

      expect{ subject.enqueue(:some_job) }.to raise_error described_class::NoWorkerError
    end
  end

end
