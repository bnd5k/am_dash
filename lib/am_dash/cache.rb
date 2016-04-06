module AMDash
  module Cache
    class << self

      def write(key, payload, expiration)
        Rails.cache.write(key, payload, expires_in: expiration)
      end

    end
  end
end
