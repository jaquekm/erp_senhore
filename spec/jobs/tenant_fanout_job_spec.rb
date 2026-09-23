# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TenantFanoutJob, type: :job do
  let(:account) { FactoryBot.create(:user).account }
  let(:other_account) { FactoryBot.create(:user).account }

  before do
    [account, other_account].each do |acc|
      Services::AccountFeatureToggler.call(account: acc, feature_key: :bling_integration, enabled: true)
      FactoryBot.create(:bling_datum, account_id: acc.id, access_token: 'token')
    end
  end

  it 'enqueues the wrapped job once per eligible account, inserting the account id between args_before and args_after' do
    expect do
      described_class.perform_now('StockSyncJob', [], ['extra'])
    end.to have_enqueued_job(StockSyncJob).with(account.id, 'extra')
       .and have_enqueued_job(StockSyncJob).with(other_account.id, 'extra')
  end

  it 'inserts the account id after args_before, matching UpdateBlingOrderStatusJob-style signatures' do
    expect do
      described_class.perform_now('UpdateBlingOrderStatusJob', %w[15 9], [])
    end.to have_enqueued_job(UpdateBlingOrderStatusJob).with('15', '9', account.id)
  end

  it 'does not enqueue anything for an account without Bling configured' do
    unrelated_account = FactoryBot.create(:user).account

    described_class.perform_now('StockSyncJob', [], [])

    expect(StockSyncJob).not_to have_been_enqueued.with(unrelated_account.id)
  end
end
