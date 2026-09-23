# == Schema Information
#
# Table name: account_features
#
#  id         :bigint           not null, primary key
#  is_enabled :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  feature_id :integer          not null
#
# Indexes
#
#  index_account_features_on_account_id_and_feature_id  (account_id,feature_id) UNIQUE
#
require 'rails_helper'

RSpec.describe AccountFeature, type: :model do
  describe '#is_enabled?' do
    let!(:user) { FactoryBot.create(:user) }

    def account_feature_for(feature_key)
      user.account.account_features.joins(:feature).find_by(features: { feature_key: feature_key })
    end

    it 'is truthy for stock feature' do
      expect(account_feature_for(FeatureKey::STOCK).is_enabled?).to eq(true)
    end

    it 'is false for bling integration feature' do
      expect(account_feature_for(FeatureKey::BLING_INTEGRATION).is_enabled?).to eq(false)
    end
  end
end
