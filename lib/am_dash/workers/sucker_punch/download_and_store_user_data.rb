require 'sucker_punch'

module AMDash
  module Worker
    module SuckerPunch
      class DownloadAndStoreUserData
        include ::SuckerPunch::Job

        def initialize(download_and_store_user_data)
          @download_and_store_user_data = download_and_store_user_data
        end

        def perform(user_id)
          download_and_store_user_data.execute(user_id)
        end

        attr_reader :download_and_store_user_data

      end
    end
  end
end
