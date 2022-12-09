FactoryBot.define do
  factory :message do
    phone_number
    body { "Hello World" }

    trait :with_external_id do
      external_id { SecureRandom.uuid }
    end
  end
end
