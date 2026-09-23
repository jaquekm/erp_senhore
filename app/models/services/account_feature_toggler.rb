# frozen_string_literal: true

module Services
  # Turns a module on/off for a client account from the admin panel,
  # keeping the account's modules internally consistent: enabling a module
  # also enables whatever it depends on, and disabling a module also
  # disables whatever depends on it -- so a client never ends up with a
  # module switched on that is silently broken because a dependency is off.
  class AccountFeatureToggler < ApplicationService
    def initialize(account:, feature_key:, enabled:)
      super()
      @account = account
      @feature_key = feature_key.to_sym
      @enabled = enabled
    end

    def call
      ActiveRecord::Base.transaction do
        enabled ? enable_with_dependencies(feature_key) : disable_with_dependents(feature_key)
      end
      account.reload
    end

    private

    attr_reader :account, :feature_key, :enabled

    def enable_with_dependencies(key)
      Feature.dependencies_for(key).each { |dependency_key| enable_with_dependencies(dependency_key) }
      set_enabled(key, true)
    end

    def disable_with_dependents(key)
      Feature.dependents_of(key).each { |dependent_key| disable_with_dependents(dependent_key) }
      set_enabled(key, false)
    end

    def set_enabled(key, is_enabled)
      feature = Feature.find_by!(feature_key: FeatureKey.const_get(key.to_s.upcase))
      account_feature = account.account_features.find_or_initialize_by(feature: feature)
      account_feature.update!(is_enabled: is_enabled)
    end
  end
end
