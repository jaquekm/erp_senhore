# frozen_string_literal: true

# == Schema Information
#
# Table name: features
#
#  id          :bigint           not null, primary key
#  feature_key :integer          default(0), not null
#  is_enabled  :boolean          default(FALSE), not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Feature < ApplicationRecord
  has_many :account_features, dependent: :destroy
  has_many :accounts, through: :account_features

  has_enumeration_for :feature_key, create_helpers: true

  # Business rule: a module that depends on another cannot work on its own
  # (e.g. Shein screens read data synced by the Bling integration). Keyed
  # and valued by FeatureKey symbol.
  DEPENDENCIES = {
    purchases: %i[stock],
    sales: %i[stock],
    production: %i[stock],
    finance: %i[sales],
    bling_integration: %i[sales],
    shein_integration: %i[bling_integration]
  }.freeze

  def self.dependencies_for(feature_key)
    DEPENDENCIES.fetch(feature_key.to_sym, [])
  end

  def self.dependents_of(feature_key)
    feature_key = feature_key.to_sym
    DEPENDENCIES.select { |_key, deps| deps.include?(feature_key) }.keys
  end

  def key
    feature_key_key
  end

  MODULE_NAMES = {
    stock: 'Estoque',
    bling_integration: 'Integração Bling',
    purchases: 'Compras',
    sales: 'Vendas',
    production: 'Produção',
    finance: 'Financeiro',
    shein_integration: 'Integração Shein'
  }.freeze

  # Ensures every FeatureKey has a master Feature row. The migration that
  # introduced these modules seeds them for a `db:migrate` upgrade path,
  # but `db:schema:load` (what a fresh test database, CI, or `db:setup`
  # actually runs) only replays table structure, never migration data --
  # so this is what makes the row set reliable everywhere. Safe to call
  # any number of times.
  def self.sync_master_data!
    MODULE_NAMES.each do |key, name|
      feature = find_or_initialize_by(feature_key: FeatureKey.const_get(key.to_s.upcase))
      feature.name = name
      feature.is_enabled = true
      feature.save!
    end
  end
end
