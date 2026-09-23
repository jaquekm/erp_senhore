# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SheinBlingOrderItems', type: :request do
  include_context 'with user signed in'

  before do
    Services::AccountFeatureToggler.call(account: user.account, feature_key: :shein_integration, enabled: true)
  end

  describe 'GET /index' do
    before { get shein_bling_order_items_path }

    it 'is success' do
      expect(response).to be_successful
    end
  end
end
