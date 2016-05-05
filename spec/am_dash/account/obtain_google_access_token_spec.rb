require 'am_dash/account/obtain_google_access_token'

describe AMDash::Account::ObtainGoogleAccessToken do
  let(:user_model) { double(:user_model) }
  let(:user) { double(:user, google_token: 'google_token',google_refresh_token: 'refreshToken', id: 666) }
  let(:yesterday) { Date.today.prev_day.to_time.to_i.to_s }
  let(:tomorrow) { Date.today.next_day.to_time.to_i.to_s }
  let(:google_key) { :key }
  let(:google_secret) { :secret }
  let(:google_response) do
    double(:google_response, code: "200",  body: response_body)
  end
  let(:response_body) do
    "{\"access_token\":\"#{fresh_token}\",\"token_type\":\"Bearer\",\"expires_in\":#{fresh_token_expiration},\"id_token\":\"asdf\"}"
  end
  let(:fresh_token) { "fresh-token" }
  let(:fresh_token_expiration) { 3600 }

  subject { described_class.new(user_model) }

  context 'user exists' do
    before do
      stub_const('ENV', { 'AM_DASH_GOOGLE_KEY' => google_key,
                          'AM_DASH_GOOGLE_SECRET' => google_secret })
      allow(user_model).to receive(:find_by_id).with(
        user.id
      ).and_return(user)
    end


    it 'returns existing token if it has not expired yet' do
      allow(user).to receive(:google_token_expiration).and_return(tomorrow)

      expect(subject.execute(user.id)).to eq user.google_token
    end

    it 'returns a fresh token original has expired' do
      allow(user).to receive(:google_token_expiration).and_return(yesterday)

      uri = URI("https://accounts.google.com/o/oauth2/token")

      params =  { 'refresh_token' => user.google_refresh_token,
                  'client_id' => google_key,
                  'client_secret' => google_secret,
                  'grant_type' => 'refresh_token'
      }

      allow(Net::HTTP).to receive(:post_form).with(
        uri,
        params
      ).and_return(google_response)

      expect(user).to receive(:update_attributes).with(
        google_token: fresh_token,
        google_token_expiration: Time.now.to_i + fresh_token_expiration
      )

      expect(subject.execute(user.id)).to eq fresh_token
    end

    it 'raises an error if unable to return a token' do
      allow(user).to receive(:google_token).and_return(nil)

      expect { subject.execute(user.id) }.to raise_error described_class:: UnableToObtainGoogleAccessTokenError
    end
  end

  context "User missing" do

  end

end
