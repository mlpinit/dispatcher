FactoryBot.define do
  factory :phone_number do
    value { '212 468 9923' }

    trait :unreceivable do
      value { '+13124687777' }
      can_receive_messages { false }
    end
  end
end
