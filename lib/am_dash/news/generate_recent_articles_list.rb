require 'net/http'
require 'json'
require 'am_dash/cache_expiration'

module AMDash
  module News
    class GenerateRecentArticlesList
      include AMDash::CacheExpiration

      def initialize(cache)
        @cache = cache
      end

      def execute
        payload = selected_articles

        write_to_cache(payload.to_json)
      end

      private

      attr_reader :cache

      def selected_articles
        all_articles.first(5).map do |article|
          {
            headline: article["headline"]["main"],
            snippet: article["snippet"],
            url: article["web_url"]
          }
        end
      end

      def all_articles
        response = Net::HTTP.get_response(request_uri)
        if response.code == "200"
          response_body = JSON.parse(response.body)
          response_body["response"]["docs"]
        else
          #TODO: Add logging
          []
        end
      end

      def request_uri
        uri = URI("http://api.nytimes.com/svc/search/v2/articlesearch.json?")

        params = {
          "begin_date" =>  start_date,
          "end_date" => end_date,
          "sort" => "newest",
          "api-key" => ENV["AM_DASH_NYT_KEY"]
        }

        uri.query = URI.encode_www_form(params)

        uri
      end

      def start_date
        yesterday = Date.today.prev_day
        yesterday.strftime("%Y%m%d")
      end

      def end_date
        Date.today.strftime("%Y%m%d")
      end

      def write_to_cache(payload)
        cache.write(
          "news",
          payload,
          FOUR_HOURS
        )
      end

    end
  end
end
