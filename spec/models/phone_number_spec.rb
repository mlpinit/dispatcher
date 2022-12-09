require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do
  describe 'associations' do
    it { should have_many(:messages) }
  end

  describe 'validations' do
    it { should validate_presence_of(:value) }
  end

  describe 'normalizers' do
    it 'formats phone number to full_e164 before persisting' do
      phone_number = PhoneNumber.create!(value: '312 (433)-9227')
      expect(phone_number.value).to eq('+13124339227')
    end
  end

  describe 'db constraints' do
    let(:phone_number) { create(:phone_number) }

    it "doesn't allow inserting a phone number without a value" do
      expect { described_class.insert_all([{}]) }
        .to raise_error(
          ActiveRecord::NotNullViolation,
          /null value in column "value/
        )
    end

    it "doesn't allow inserting a duplicate value" do
      expect { described_class.insert_all!([{value: phone_number.value}]) }
        .to raise_error(
          ActiveRecord::RecordNotUnique,
          /duplicate key value violates unique constraint/
        )
    end
  end

  it 'can receive messages by default' do
    expect(described_class.new.can_receive_messages?).to be(true)
  end
end
