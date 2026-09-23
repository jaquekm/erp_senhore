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
class Account < ApplicationRecord
  has_many :account_features, dependent: :destroy
  has_many :features, through: :account_features
  has_many :users, dependent: :restrict_with_error
  has_many :account_sessions, dependent: :destroy

  belongs_to :user, inverse_of: :owned_account

  before_create :set_account_features

  validates :max_users, numericality: { greater_than_or_equal_to: 1 }
  validates :max_concurrent_sessions, numericality: { greater_than_or_equal_to: 1 }

  # Modules a brand new client account starts with. Matches what was always
  # unconditionally visible before module gating existed. Integrations
  # (Bling/Shein) stay off until an admin enables them on a plan.
  DEFAULT_ENABLED_FEATURE_KEYS = [
    FeatureKey::STOCK, FeatureKey::PURCHASES, FeatureKey::SALES,
    FeatureKey::PRODUCTION, FeatureKey::FINANCE
  ].freeze
  DEFAULT_DISABLED_FEATURE_KEYS = [FeatureKey::BLING_INTEGRATION, FeatureKey::SHEIN_INTEGRATION].freeze

  def feature_enabled?(feature_key)
    feature_key = feature_key.to_s
    @feature_flags ||= account_features.includes(:feature).index_by { |af| af.feature.key.to_s }
    @feature_flags[feature_key]&.is_enabled? || false
  end

  # Accounts the Bling sync cron jobs should run for: the module is turned
  # on AND the account actually went through the Bling OAuth flow (has a
  # token). Used to fan a job that used to hardcode account_id 1 out to
  # every real client account instead.
  def self.bling_sync_enabled_ids
    bling_feature = Feature.find_by(feature_key: FeatureKey::BLING_INTEGRATION)
    return [] unless bling_feature

    enabled_account_ids = AccountFeature.where(feature: bling_feature, is_enabled: true).pluck(:account_id)
    BlingDatum.where(account_id: enabled_account_ids).where.not(access_token: nil).distinct.pluck(:account_id)
  end

  def seats_available?
    users.count < max_users
  end

  def active_sessions_count
    account_sessions.active.count
  end

  private

  def set_account_features
    Feature.where(feature_key: DEFAULT_ENABLED_FEATURE_KEYS).find_each do |feature|
      account_features.build(feature: feature, is_enabled: true)
    end
    Feature.where(feature_key: DEFAULT_DISABLED_FEATURE_KEYS).find_each do |feature|
      account_features.build(feature: feature, is_enabled: false)
    end
  end
end
