# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::AccountFeatureToggler do
  let(:user) { FactoryBot.create(:user) }
  let(:account) { user.account }

  def enabled?(feature_key)
    account.reload.feature_enabled?(feature_key)
  end

  describe 'enabling a module' do
    it 'also enables the modules it depends on' do
      described_class.call(account: account, feature_key: :bling_integration, enabled: true)

      expect(enabled?(:bling_integration)).to be true
      expect(enabled?(:sales)).to be true # bling_integration depends on sales
      expect(enabled?(:stock)).to be true # sales depends on stock
    end

    it 'cascades through more than one level of dependency' do
      described_class.call(account: account, feature_key: :shein_integration, enabled: true)

      expect(enabled?(:shein_integration)).to be true
      expect(enabled?(:bling_integration)).to be true
      expect(enabled?(:sales)).to be true
      expect(enabled?(:stock)).to be true
    end
  end

  describe 'disabling a module' do
    before do
      described_class.call(account: account, feature_key: :shein_integration, enabled: true)
    end

    it 'also disables everything that depends on it, so nothing is left half-working' do
      described_class.call(account: account, feature_key: :stock, enabled: false)

      expect(enabled?(:stock)).to be false
      expect(enabled?(:sales)).to be false
      expect(enabled?(:bling_integration)).to be false
      expect(enabled?(:shein_integration)).to be false
    end

    it 'leaves unrelated modules untouched' do
      described_class.call(account: account, feature_key: :bling_integration, enabled: false)

      expect(enabled?(:bling_integration)).to be false
      expect(enabled?(:shein_integration)).to be false # depends on bling, cascaded off
      expect(enabled?(:stock)).to be true # not a dependent, stays on
      expect(enabled?(:purchases)).to be true
    end
  end
end
