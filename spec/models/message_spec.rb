require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:phone_number) }
  end

  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_most(160) }
  end

  describe 'db constraints' do
    let(:phone_number) { create(:phone_number) }

    it "doesn't allow inserting a message without a phone number reference" do
      expect { described_class.insert_all([{body: 'some text' }]) }
        .to raise_error(
          ActiveRecord::NotNullViolation,
          /null value in column "phone_number_id/
        )
    end

    it "doesn't allow inserting a message without a body" do
      expect { described_class.insert_all([{phone_number_id: phone_number.id}]) }
        .to raise_error(
          ActiveRecord::NotNullViolation,
          /null value in column "body/
        )
    end
  end
end
