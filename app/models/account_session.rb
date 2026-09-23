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
class AccountSession < ApplicationRecord
  belongs_to :account
  belongs_to :user

  # A browser tab that goes quiet for this long frees up its concurrent
  # login slot, so a closed browser or a crashed tab doesn't permanently
  # burn a seat until someone notices.
  ACTIVE_WINDOW = 20.minutes

  scope :active, -> { where(last_active_at: ACTIVE_WINDOW.ago..) }
  scope :stale, -> { where(last_active_at: ...ACTIVE_WINDOW.ago) }
end
