# frozen_string_literal: true

# == Schema Information
#
# Table name: account_sessions
#
#  id             :bigint           not null, primary key
#  last_active_at :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  session_id     :string           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_account_sessions_on_account_id                     (account_id)
#  index_account_sessions_on_account_id_and_last_active_at  (account_id,last_active_at)
#  index_account_sessions_on_session_id                     (session_id) UNIQUE
#  index_account_sessions_on_user_id                        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe AccountSession, type: :model do
  let(:user) { FactoryBot.create(:user) }

  def create_session(session_id:, last_active_at:)
    described_class.create!(account: user.account, user: user, session_id: session_id, last_active_at: last_active_at)
  end

  describe '.active' do
    it 'includes sessions active within the window' do
      recent = create_session(session_id: 'recent', last_active_at: 1.minute.ago)

      expect(described_class.active).to include(recent)
    end

    it 'excludes sessions idle past the window' do
      stale = create_session(session_id: 'stale', last_active_at: 1.hour.ago)

      expect(described_class.active).not_to include(stale)
    end
  end

  describe '.stale' do
    it 'is the complement of .active' do
      stale = create_session(session_id: 'stale', last_active_at: 1.hour.ago)

      expect(described_class.stale).to include(stale)
      expect(described_class.active).not_to include(stale)
    end
  end
end
