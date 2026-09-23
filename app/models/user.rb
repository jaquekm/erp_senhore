# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE), not null
#  company_name           :string
#  cpf_cnpj               :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  phone                  :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("owner"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  index_users_on_account_id            (account_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { owner: 0, member: 1 }

  # The tenant/workspace this user signs in as. For an owner this is the
  # account they created on sign up; for a member it's the account an
  # admin (or the owner) assigned them to.
  belongs_to :account, optional: true

  # The account this user owns, if any (accounts.user_id => users.id).
  # Kept separate from #account so an admin-created member user -- who
  # belongs to someone else's account -- never accidentally owns one.
  has_one :owned_account, class_name: 'Account', inverse_of: :user, dependent: :restrict_with_error

  before_validation :build_owned_account_if_needed, on: :create
  after_create :finalize_owned_account, if: :owned_account

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_seat_disabled
  end

  private

  # Self sign-up (and an admin creating a client's first/owner login) both
  # provision a brand new Account. A member user created under an existing
  # account arrives with account_id already set and skips this entirely.
  def build_owned_account_if_needed
    return if account_id.present?

    self.role = :owner
    build_owned_account
  end

  def finalize_owned_account
    owned_account.update(company_name:)
    update_column(:account_id, owned_account.id) # rubocop:disable Rails/SkipsModelValidations
  end
end
