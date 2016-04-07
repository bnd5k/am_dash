require 'sucker_punch'
require 'am_dash/am_dash'

module AMDash
  module Worker
    module SuckerPunch
      class DownloadAndStoreUserData
        include ::SuckerPunch::Job

        def perform(user_id)
          AMDash.download_and_store_user_data.execute(user_id)
        end

      end
    end
  end
end
