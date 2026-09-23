# frozen_string_literal: true

# Enforces Account#max_concurrent_sessions: once a client account is
# already at its live-session limit, a new login is bounced back out
# instead of silently sharing a seat. Admin users are a separate Devise
# scope and never go through this controller stack.
module SessionConcurrencyGuard
  extend ActiveSupport::Concern

  included do
    before_action :enforce_session_concurrency_limit
    before_action :track_account_session
  end

  private

  def enforce_session_concurrency_limit
    return if current_user.blank? || current_account.blank?

    current_account.account_sessions.stale.delete_all
    return if session_limit_available?

    bounce_over_session_limit!
  end

  def session_limit_available?
    return true if current_account.account_sessions.active.exists?(session_id: account_session_token)

    current_account.account_sessions.active.count < current_account.max_concurrent_sessions
  end

  def bounce_over_session_limit!
    limit = current_account.max_concurrent_sessions
    sign_out(current_user)
    redirect_to new_user_session_path,
                alert: "Limite de #{limit} usuário(s) conectado(s) ao mesmo tempo atingido para esta conta. " \
                       'Peça para outro usuário sair ou fale com o administrador para aumentar o limite.'
  end

  def track_account_session
    return if current_user.blank? || current_account.blank?

    account_session = AccountSession.find_or_initialize_by(session_id: account_session_token)
    account_session.account = current_account
    account_session.user = current_user
    account_session.last_active_at = Time.current
    account_session.save!
  end

  # Devise rotates the underlying Rack session id on sign in (session
  # fixation protection), so `session.id` is not a stable key for "this
  # browser's login" across a single sign-in. A token we mint ourselves and
  # store as session data survives that rotation (the id changes, the
  # stored data doesn't), so it -- not session.id -- is what identifies one
  # concurrent login.
  def account_session_token
    session[:account_session_token] ||= SecureRandom.hex(16)
  end
end
