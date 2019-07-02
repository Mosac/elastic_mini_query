require "bundler/setup"
require "elastic_mini_query"

require "lib/real_client"

RSpec.describe RealClient do

  ##
  # @return RealClient
  let!(:client) {
    RealClient.new
  }

  context "indice not exists" do
    context "raise exception" do
      it "indice not exists" do
        expect{client.empty_index.execute!}.to raise_error(ElasticMiniQuery::ResponseError)
      end
    end

    context "not raise exception" do
      it "indice not exists" do
        res = client.empty_index.execute

        expect(res.error?).to eq(true)
        s = res.summary
        expect(s.total_hits).to eq(0)

        expect(res.error.reason).to eq("no such index [not-exists]")
        expect(res.error.type).to eq("index_not_found_exception")
      end
    end
  end

  context "get all data" do
    it "get all data" do
      res = client.get_all_docs.execute

      s = res.summary
      r = res.search

      expect(s.total_hits).to eq(1000)
      expect(client.size).to eq(100)

      doc = r.sources.first
      expect(doc["address"]).to eq("880 Holmes Lane")
      expect(doc["balance"]).to eq(39225)
    end
  end

  context "String search" do

    it "search all field" do
      res = client.search("Fulton").execute
      s   = res.summary

      expect(s.total_hits).to eq(3)
    end

    it "search by bank address" do
      res = client.search_by_address("Street").execute
      s   = res.summary

      expect(s.total_hits).to eq(385)

      res = client.search_by_address("Bristol").execute
      s   = res.summary

      expect(s.total_hits).to eq(1)

    end

    it "multiple columns specified" do
      res = client.search("Fulton", [:address]).execute

      s = res.summary
      expect(s.total_hits).to eq(1)

      res = client.search("Fulton", [:address, :firstname]).execute

      s = res.summary
      expect(s.total_hits).to eq(2)
    end

    context "match phrase" do
      it "word search" do
        res = client.search("Fulton Street").execute
        s   = res.summary
        expect(s.total_hits).to eq(385)
      end

      it "mutch phrase" do
        res = client.search_phrase("Fulton Street").execute
        s   = res.summary
        expect(s.total_hits).to eq(1)

        res = client.search_phrase("Bristol Street").execute
        s   = res.summary
        expect(s.total_hits).to eq(1)
      end
    end
  end

  context "aggregation" do
    context "Metrics Aggregation" do
      it "min, max, avg" do
        res = client.debug!.search("Street", [:address, :firstname]).agg_balance.execute
        s = res.summary
        a = res.aggs

        expect(s.total_hits).to eq(385)
        expect(a["balance_min"]).to eq(1031.0)
        expect(a["balance_max"]).to eq(49795.0)
      end
    end
    it "summary_by" do

    end

    it "date_histgram" do
    end
  end
end
