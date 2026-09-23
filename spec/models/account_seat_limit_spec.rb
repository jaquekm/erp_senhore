# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Account seat limits', type: :model do
  let(:owner) { FactoryBot.create(:user) }
  let(:account) { owner.account }

  it 'the owner counts as one of the account seats' do
    expect(account.users).to include(owner)
    expect(owner).to be_owner
  end

  it 'reports seats as available while under max_users' do
    account.update!(max_users: 2)

    expect(account.seats_available?).to be true
  end

  it 'reports no seats available once max_users is reached' do
    account.update!(max_users: 1)

    expect(account.seats_available?).to be false
  end

  it 'lets an admin add a member user under the same account without creating a new account' do
    account.update!(max_users: 2)

    expect do
      account.users.create!(email: Faker::Internet.email, password: 'password123', role: :member)
    end.to change(Account, :count).by(0).and change(User, :count).by(1)
  end

  it 'refuses to delete an account that still has users' do
    account # ensure it (and its owner) exist before measuring the count

    expect { account.destroy }.not_to change(Account, :count)
    expect(account.errors[:base]).to be_present
  end
end
