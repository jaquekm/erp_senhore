# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Module gating blocks direct URL access', type: :request do
  include_context 'with user signed in'

  it 'blocks a disabled module even when the URL is hit directly' do
    Services::AccountFeatureToggler.call(account: user.account, feature_key: :purchases, enabled: false)

    get suppliers_path

    expect(response).to have_http_status(:forbidden)
  end

  it 'allows the module again once an admin re-enables it' do
    Services::AccountFeatureToggler.call(account: user.account, feature_key: :purchases, enabled: false)
    Services::AccountFeatureToggler.call(account: user.account, feature_key: :purchases, enabled: true)

    get suppliers_path

    expect(response).to have_http_status(:success)
  end
end
