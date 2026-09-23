# frozen_string_literal: true

class AddSeatLimitsToAccounts < ActiveRecord::Migration[7.0]
  def change
    # Existing accounts already operate with a single owner user today, so a
    # 1/1 default preserves current behavior exactly. Admins raise these
    # limits per client afterwards.
    add_column :accounts, :max_users, :integer, null: false, default: 1
    add_column :accounts, :max_concurrent_sessions, :integer, null: false, default: 1
  end
end
