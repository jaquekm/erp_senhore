# frozen_string_literal: true

# Backs AccountFeature's uniqueness validation with a real DB constraint,
# so a race between two requests can't leave an account with two rows for
# the same module (which would make Account#feature_enabled? ambiguous).
class AddUniqueIndexToAccountFeatures < ActiveRecord::Migration[7.0]
  def change
    add_index :account_features, %i[account_id feature_id], unique: true
  end
end
