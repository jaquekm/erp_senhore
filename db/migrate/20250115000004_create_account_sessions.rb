# frozen_string_literal: true

class CreateAccountSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :account_sessions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :session_id, null: false
      t.datetime :last_active_at, null: false

      t.timestamps
    end

    add_index :account_sessions, :session_id, unique: true
    add_index :account_sessions, %i[account_id last_active_at]
  end
end
