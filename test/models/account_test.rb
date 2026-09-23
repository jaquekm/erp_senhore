# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                      :bigint           not null, primary key
#  company_name            :string
#  max_concurrent_sessions :integer          default(1), not null
#  max_users               :integer          default(1), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_accounts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
