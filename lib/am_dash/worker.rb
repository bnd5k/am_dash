require 'sucker_punch'
require 'am_dash/am_dash'
require 'am_dash/workers/sucker_punch/download_and_store_user_data'

module AMDash
  module Worker
    class << self
      #Generic interface for worker.  Allows me to start off with silly, lightweight worker
      #but then upgrade to something like Resque when needed

      def enqueue(job_name, *args)

        if ENV["AM_DASH_WORKER"] == "sucker_punch"
          #env variable here will ultimately allow for hotswapping workers
          #totally premature optimization, but I've been wanting to play withsomething like this
          #lately
          job = sucker_punch_job_from_string(job_name)    
          job.perform(*args)
        else
          raise NoWorkerError
        end

      end

      private

      def sucker_punch_job_from_string(job_name)
        case job_name.to_sym
        when :download_and_store_user_data
          AMDash::Worker::SuckerPunch::DownloadAndStoreUserData.new
        else
          raise NoJobFoundError 
        end
      end

    end

    class NoJobFoundError < StandardError ; end  
    class NoWorkerError < StandardError ; end

  end
end
