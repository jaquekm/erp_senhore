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
FactoryBot.define do
  factory :bling_module_situation do
    sequence(:situation_id) { |n| n }
    name { "Situation #{Faker::Lorem.word}" }
    module_id { Faker::Number.number(digits: 2).to_i }  # Ensure this is an integer
    inherited_id { Faker::Number.number(digits: 2) }
    color { Faker::Color.hex_color }
  end
end
