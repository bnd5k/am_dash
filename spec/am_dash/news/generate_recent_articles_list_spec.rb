require 'am_dash/news/generate_recent_articles_list'

describe AMDash::News::GenerateRecentArticlesList do
  let(:cache) { double(:cache) }
  let(:news_query_response) { double(:news_query_response, code: "200",  body: response_body) }
  let(:response_body) do
    "{\"response\":{\"meta\":{\"hits\":1922,\"time\":71,\"offset\":0},\"docs\":[{\"web_url\":\"http://www.nytimes.com/aponline/2016/04/06/us/ap-us-teacher-recruitment.html\",\"snippet\":\"The Hawaii Department of Education has been seeking out educators from the mainland to deal with the state's growing teacher shortage.\",\"lead_paragraph\":\"The Hawaii Department of Education has been seeking out educators from the mainland to deal with the state's growing teacher shortage.\",\"abstract\":null,\"print_page\":null,\"blog\":[],\"source\":\"AP\",\"multimedia\":[],\"headline\":{\"main\":\"Hawaii Looks to Mainland to Deal With Big Teacher Shortage\",\"print_headline\":\"Hawaii Looks to Mainland to Deal With Big Teacher Shortage\"},\"keywords\":[],\"pub_date\":\"2016-04-06T22:38:37Z\",\"document_type\":\"article\",\"news_desk\":\"None\",\"section_name\":\"U.S.\",\"subsection_name\":null,\"byline\":{\"person\":[],\"original\":\"By THE ASSOCIATED PRESS\",\"organization\":\"THE ASSOCIATED PRESS\"},\"type_of_material\":\"News\",\"_id\":\"5705c92538f0d86865ca52ef\",\"word_count\":\"381\",\"slideshow_credits\":null}]}}" 
  end

  subject { described_class.new(cache) }

  before do
    stub_const('ENV', {'AM_DASH_NYT_KEY' => 'asdf'})
  end

  it "pulls a bunch of data from a news API" do
    today = Date.today.strftime("%Y%m%d")
    yesterday = Date.today.prev_day.strftime("%Y%m%d")

    uri = URI("http://api.nytimes.com/svc/search/v2/articlesearch.json?begin_date=#{yesterday}&end_date=#{today}&sort=newest&api-key=#{ENV["AM_DASH_NYT_KEY"]}")

    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(news_query_response)

    article_collection = [{:headline=>"Hawaii Looks to Mainland to Deal With Big Teacher Shortage", :snippet=>"The Hawaii Department of Education has been seeking out educators from the mainland to deal with the state's growing teacher shortage.", :url=>"http://www.nytimes.com/aponline/2016/04/06/us/ap-us-teacher-recruitment.html"}]

    expect(cache).to receive(:write).with(
      "news",
      article_collection.to_json,
      described_class::FOUR_HOURS
    )

    subject.execute
  end

  context "failure" do
    it "handles 400 error code response" do
      response_to_bad_request = Net::HTTPResponse.new(1.0, 400, "Your request is bad and you should feel bad!")

      allow(Net::HTTP).to receive(:get_response).and_return(response_to_bad_request)

      expect(cache).to receive(:write).with(
        "news",
        [].to_json,
        described_class::FOUR_HOURS
      )

      subject.execute
    end

    it "handles 500 error code response" do
      response_from_broken_news_service = Net::HTTPResponse.new(1.0, 400, "Barf!")

      allow(Net::HTTP).to receive(:get_response).and_return(response_from_broken_news_service)

      expect(cache).to receive(:write).with(
        "news",
        [].to_json,
        described_class::FOUR_HOURS
      )

      subject.execute
    end
  end

end
