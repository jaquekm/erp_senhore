# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin manages client accounts', type: :request do
  it 'is unreachable for an anonymous visitor' do
    get admin_accounts_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  context 'when signed in as an admin' do
    let(:admin) { FactoryBot.create(:admin_user) }

    before { sign_in admin, scope: :admin_user }

    it 'lets an admin create a client account with an owner login' do
      expect do
        post admin_accounts_path, params: {
          account: {
            company_name: 'Loja Teste',
            owner_email: 'owner@example.com',
            owner_password: 'password123',
            max_users: 3,
            max_concurrent_sessions: 2
          }
        }
      end.to change(Account, :count).by(1).and change(User, :count).by(1)

      account = Account.last
      expect(account.max_users).to eq(3)
      expect(account.max_concurrent_sessions).to eq(2)
      expect(account.user.email).to eq('owner@example.com')
      expect(account.user).to be_owner
    end

    describe 'once a client account exists' do
      let(:owner) { FactoryBot.create(:user) }
      let!(:account) { owner.account.tap { |a| a.update!(max_users: 2) } }

      it 'toggles a module on for the account' do
        patch toggle_feature_admin_account_path(account), params: { feature_key: 'bling_integration', enabled: 'true' }

        expect(account.reload.feature_enabled?(:bling_integration)).to be true
      end

      it 'adds a member user under the existing account, not a new one' do
        expect do
          post admin_account_users_path(account), params: { user: { email: 'member@example.com', password: 'password123' } }
        end.to change(Account, :count).by(0).and change(User, :count).by(1)

        member = User.find_by(email: 'member@example.com')
        expect(member).to be_member
        expect(member.account).to eq(account)
      end

      it 'refuses to add a member once max_users is reached' do
        account.update!(max_users: 1)

        expect do
          post admin_account_users_path(account), params: { user: { email: 'member@example.com', password: 'password123' } }
        end.not_to change(User, :count)
      end

      it 'refuses to remove the account owner' do
        expect do
          delete admin_account_user_path(account, owner)
        end.not_to change(User, :count)
      end
    end
  end
end
