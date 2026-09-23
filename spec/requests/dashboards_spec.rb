# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  describe 'GET /others_status' do
    include_context 'with user signed in'

    before do
      Services::AccountFeatureToggler.call(account: user.account, feature_key: :bling_integration, enabled: true)
    end

    it 'returns http success' do
      get '/dashboards/others_status'
      expect(response).to have_http_status(:success)
    end
  end
end
