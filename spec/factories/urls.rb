FactoryBot.define do
  factory :url do
    sequence(:short_code) { |n| "code#{n}" }
    long_url { "https://example.com/some/long/path" }
  end
end
