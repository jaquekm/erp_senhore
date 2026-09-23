# frozen_string_literal: true

class AddAccountMembershipToUsers < ActiveRecord::Migration[7.0]
  def up
    add_reference :users, :account, foreign_key: true, index: true
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :active, :boolean, null: false, default: true

    # Every user that exists today is the owner of the account they created
    # on sign up (accounts.user_id => users.id). Backfill users.account_id
    # from that relationship so current logins keep working unchanged.
    execute <<~SQL.squish
      UPDATE users
      SET account_id = accounts.id
      FROM accounts
      WHERE accounts.user_id = users.id
    SQL
  end

  def down
    remove_column :users, :active
    remove_column :users, :role
    remove_reference :users, :account, foreign_key: true, index: true
  end
end
