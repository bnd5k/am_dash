require 'am_dash/account/find_or_create_from_google'

module AMDash 
  class << self

    def find_or_create_from_google(auth_data)
      context = AMDash::Account::FindOrCreateFromGoogle.new(User)
      context.execute(auth_data)
    end

  end
end
