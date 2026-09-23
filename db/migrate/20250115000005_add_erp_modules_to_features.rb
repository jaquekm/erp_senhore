# frozen_string_literal: true

# Introduces the module/feature flags that the admin panel toggles per
# client account, and guarantees every FeatureKey (including the two that
# already existed) has a master Feature row -- previously "stock" and
# "bling_integration" were only ever created ad hoc by db/seeds.rb, so a
# real deployment could be missing them entirely.
#
# Existing accounts are backfilled so nothing they could already see
# disappears: stock, purchases, sales, production and finance were never
# gated before, so they are turned on for every current account whenever
# their account_feature row is missing. shein_integration is a genuinely
# new gate, and it depends on bling_integration (the Shein screens read
# Bling-synced order data), so it mirrors whatever bling_integration is
# already set to (or defaulted to) for that account.
class AddErpModulesToFeatures < ActiveRecord::Migration[7.0]
  ALL_MODULES = {
    0 => 'Estoque',
    1 => 'Integração Bling',
    2 => 'Compras',
    3 => 'Vendas',
    4 => 'Produção',
    5 => 'Financeiro',
    6 => 'Integração Shein'
  }.freeze

  ALWAYS_ON_FOR_EXISTING_ACCOUNTS = [0, 2, 3, 4, 5].freeze # stock, purchases, sales, production, finance
  BLING_INTEGRATION_KEY = 1
  SHEIN_INTEGRATION_KEY = 6

  def up
    ALL_MODULES.each do |feature_key, name|
      next if execute("SELECT 1 FROM features WHERE feature_key = #{feature_key} LIMIT 1").any?

      execute <<~SQL.squish
        INSERT INTO features (feature_key, name, is_enabled, created_at, updated_at)
        VALUES (#{feature_key}, #{quote(name)}, TRUE, NOW(), NOW())
      SQL
    end

    account_ids = execute('SELECT id FROM accounts').map { |row| row['id'] }
    account_ids.each do |account_id|
      backfill_account_feature(account_id, ALWAYS_ON_FOR_EXISTING_ACCOUNTS, enabled: true)

      bling_enabled = fetch_is_enabled(account_id, BLING_INTEGRATION_KEY)
      backfill_account_feature(account_id, [BLING_INTEGRATION_KEY], enabled: false) if bling_enabled.nil?
      bling_enabled = fetch_is_enabled(account_id, BLING_INTEGRATION_KEY) if bling_enabled.nil?

      backfill_account_feature(account_id, [SHEIN_INTEGRATION_KEY], enabled: bling_enabled || false)
    end
  end

  def down
    feature_ids = execute("SELECT id FROM features WHERE feature_key IN (#{ALL_MODULES.keys.join(',')})").map { |r| r['id'] }
    return if feature_ids.empty?

    execute "DELETE FROM account_features WHERE feature_id IN (#{feature_ids.join(',')})"
    execute "DELETE FROM features WHERE id IN (#{feature_ids.join(',')})"
  end

  private

  def fetch_is_enabled(account_id, feature_key)
    row = execute(<<~SQL.squish).first
      SELECT af.is_enabled AS is_enabled
      FROM account_features af
      JOIN features f ON f.id = af.feature_id
      WHERE af.account_id = #{account_id} AND f.feature_key = #{feature_key}
      LIMIT 1
    SQL
    return nil if row.blank?

    ActiveRecord::Type::Boolean.new.cast(row['is_enabled'])
  end

  def backfill_account_feature(account_id, feature_keys, enabled:)
    feature_keys.each do |feature_key|
      feature_id = execute("SELECT id FROM features WHERE feature_key = #{feature_key} LIMIT 1").first['id']

      exists = execute(<<~SQL.squish).any?
        SELECT 1 FROM account_features
        WHERE account_id = #{account_id} AND feature_id = #{feature_id}
        LIMIT 1
      SQL
      next if exists

      execute <<~SQL.squish
        INSERT INTO account_features (account_id, feature_id, is_enabled, created_at, updated_at)
        VALUES (#{account_id}, #{feature_id}, #{enabled}, NOW(), NOW())
      SQL
    end
  end
end
