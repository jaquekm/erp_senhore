# == Schema Information
#
# Table name: production_products
#
#  id               :bigint           not null, primary key
#  delivery_date    :date
#  dirty            :integer          default(0)
#  discard          :integer          default(0)
#  error            :integer          default(0)
#  lost_pieces      :integer          default(0)
#  pieces_delivered :integer
#  quantity         :integer
#  returned         :boolean          default(FALSE)
#  total_price      :decimal(10, 2)
#  unit_price       :decimal(10, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  product_id       :bigint           not null
#  production_id    :bigint           not null
#
# Indexes
#
#  index_production_products_on_product_id     (product_id)
#  index_production_products_on_production_id  (production_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (production_id => productions.id)
#
FactoryBot.define do
  factory :production_product do
    association :production
    association :product
    quantity { 5 }
    pieces_delivered { 0 }
    dirty { 0 }
    error { 0 }
    discard { 0 }
  end
end
