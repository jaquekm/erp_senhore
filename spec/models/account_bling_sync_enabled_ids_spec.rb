# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, '.bling_sync_enabled_ids' do
  let(:account_with_bling) { FactoryBot.create(:user).account }
  let(:account_without_feature) { FactoryBot.create(:user).account }
  let(:account_without_token) { FactoryBot.create(:user).account }

  before do
    Services::AccountFeatureToggler.call(account: account_with_bling, feature_key: :bling_integration, enabled: true)
    FactoryBot.create(:bling_datum, account_id: account_with_bling.id, access_token: 'token')

    Services::AccountFeatureToggler.call(account: account_without_token, feature_key: :bling_integration,
                                          enabled: true)
    FactoryBot.create(:bling_datum, account_id: account_without_token.id, access_token: nil)
  end

  it 'includes only accounts with the module enabled and a real Bling token' do
    ids = described_class.bling_sync_enabled_ids

    expect(ids).to include(account_with_bling.id)
    expect(ids).not_to include(account_without_feature.id)
    expect(ids).not_to include(account_without_token.id)
  end
end
