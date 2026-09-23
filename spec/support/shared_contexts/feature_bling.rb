require 'spec_helper'

shared_context 'with bling feature' do
  before do
    Services::AccountFeatureToggler.call(account: user.account, feature_key: :bling_integration, enabled: true)
  end
end
