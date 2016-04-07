module AMDash
  module Cache
    class << self

      def write(key, payload, expiration)
        Rails.cache.write(key, payload, expires_in: expiration)
      end
      
      def read(key)
        Rails.cache.read(key)
      end

    end
  end
end
