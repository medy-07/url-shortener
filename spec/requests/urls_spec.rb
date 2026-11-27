require "rails_helper"

RSpec.describe "Short URLs", type: :request do
  describe "POST /api/urls" do
    it "creates a short url and returns 201 with short_url" do
      expect {
        post "/api/urls", params: { long_url: "https://example.com/a/very/long/path" }, as: :json
      }.to change(Url, :count).by(1)

      expect(response).to have_http_status(:created)
      code = Url.last.short_code
      expect(response.parsed_body).to eq("short_url" => "http://www.example.com/#{code}")
    end

    it "accepts a custom alias and expiry" do
      post "/api/urls", params: { long_url: "https://example.com", alias: "promo", expires_at: 1.day.from_now.iso8601 }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["short_url"]).to end_with("/promo")
      expect(Url.find_by(short_code: "promo").expires_at).to be_present
    end

    it "returns 422 with errors for an invalid url" do
      expect {
        post "/api/urls", params: { long_url: "not-a-url" }, as: :json
      }.not_to change(Url, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["long_url"]).to be_present
    end

    it "returns 422 when long_url is missing" do
      post "/api/urls", params: {}, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["long_url"]).to include("Long url can't be blank")
    end
  end

  describe "GET /:code" do
    it "redirects with 302 to the long url" do
      url = create(:url, long_url: "https://example.com/target")

      get "/#{url.short_code}"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("https://example.com/target")
    end

    it "round-trips a url created through the API" do
      post "/api/urls", params: { long_url: "https://example.com/round-trip" }, as: :json
      get URI(response.parsed_body["short_url"]).path

      expect(response).to redirect_to("https://example.com/round-trip")
    end

    it "returns 404 for an unknown code" do
      get "/nope123"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 410 for an expired url" do
      url = create(:url, expires_at: 1.hour.from_now)
      url.update_column(:expires_at, 1.minute.ago)

      get "/#{url.short_code}"
      expect(response).to have_http_status(:gone)
    end

    it "returns 410 for an inactive url" do
      url = create(:url, is_active: false)

      get "/#{url.short_code}"
      expect(response).to have_http_status(:gone)
    end

    it "does not shadow the health check" do
      get "/up"
      expect(response).to have_http_status(:ok)
    end
  end
end
