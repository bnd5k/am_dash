require 'am_dash/account/find_or_create_from_google'

describe AMDash::Account::FindOrCreateFromGoogle do
  let(:user_model) { double(:user_model) }
  let(:account) { double(:account) }

  let(:auth_data) do
    {"provider"=>"google_oauth2",
     "uid"=>"105601260094057036217",
     "info"=> {
       "name"=>"Joe Chainsaw",
       "email"=>"joejoe@Chainsaw.com",
       "first_name"=>"Joe",
       "last_name"=>"Chainsaw",
       "image"=>"https://lh6.google.com.photo.jpg",
       "urls"=>{"Google"=>"https://plus.google.com/1"}
     },
     "credentials"=> {
       "token"=>"aTgClLHOj6H03EfqlN5dUOds4ikD5g",
       "refresh_token"=>"1/ELKAEz1RWQqsmZPAEZuR",
       "expires_at"=>1459901552,
       "expires"=>true
     },
     "extra"=> {
       "id_token"=> "barf",
       "raw_info"=> {
         "id"=>"1056057036217",
         "email"=>"joejoe@Chainsaw.com",
         "verified_email"=>true,
         "name"=>"Joe Chainsaw",
         "given_name"=>"Ben",
         "family_name"=>"Downey",
         "link"=>"https://plus.google.com/105601260094057036217",
         "picture"=>"https://lh6.googleusercontent.com/photo.jpg", 
         "gender"=>"male",
         "locale"=>"en",
         "hd"=>"chainsaw.com"}
     }
    }
  end

  subject { described_class.new(user_model) }
          
  it 'fails gracefully' do
    expect(subject.execute(nil)).to be_nil
  end

  it 'finds account with existing google creds' do
    allow(user_model).to receive(:where).with(
      google_uid: auth_data["uid"]
    ).and_return([account])

    expect(subject.execute(auth_data)).to eq account
  end

  it 'creates new account when existing account not found' do
    allow(SecureRandom).to receive(:base64).with(16).and_return(:barf)

    allow(user_model).to receive(:where).with(
      google_uid: auth_data["uid"]
    ).and_return([])

    account_data = { 
      first_name: auth_data["info"]["first_name"],
      email: auth_data["info"]["email"],
      google_uid: auth_data["uid"],
      google_token: auth_data["credentials"]["token"],
      google_refresh_token: auth_data["credentials"]["refresh_token"],
      google_token_expiration: auth_data["credentials"]["expires_at"],
      password: :barf
    }

    allow(user_model).to receive(:create!).with(account_data).and_return(account)

    expect(subject.execute(auth_data)).to eq account
  end

end
