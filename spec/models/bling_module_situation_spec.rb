# frozen_string_literal: true

# == Schema Information
#
# Table name: bling_module_situations
#
#  id           :bigint           not null, primary key
#  color        :string
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inherited_id :integer
#  module_id    :integer          not null
#  situation_id :integer          not null
#
# Indexes
#
#  index_bling_module_situations_on_situation_id  (situation_id) UNIQUE
#
require 'rails_helper'

RSpec.describe BlingModuleSituation, type: :model do
  describe 'validations' do
    subject { build(:bling_module_situation) }

    it { should validate_presence_of(:situation_id) }
    it { should validate_uniqueness_of(:situation_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:module_id) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:bling_module_situation)).to be_valid
    end
  end

  describe 'attributes' do
    it { should respond_to(:situation_id) }
    it { should respond_to(:name) }
    it { should respond_to(:inherited_id) }
    it { should respond_to(:color) }
    it { should respond_to(:module_id) }
  end

  describe 'creation' do
    it 'can be created with valid attributes' do
      bling_module_situation = BlingModuleSituation.new(
        situation_id: 1,
        name: 'Test Situation',
        module_id: 1,
        inherited_id: 2,
        color: '#FF0000'
      )
      expect(bling_module_situation).to be_valid
    end
  end

  describe 'uniqueness' do
    it 'does not allow duplicate situation_ids' do
      create(:bling_module_situation, situation_id: 1)
      duplicate = build(:bling_module_situation, situation_id: 1)
      expect(duplicate).not_to be_valid
    end
  end
end
