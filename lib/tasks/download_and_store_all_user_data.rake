require 'am_dash/am_dash'

namespace :am_dash do
  task :data_dump => :environment do |t, args|

    #cache expires every 4 hours, so this should be run near morning time (4 hours catches US  Time zones)

    User.all.each do |user|
      AMDash.download_and_store_user_data.execute(user.id)
    end

  end
end
