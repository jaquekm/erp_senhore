# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def destroy
      token = session[:account_session_token]
      AccountSession.where(session_id: token).delete_all if current_user && token
      super
    end
  end
end
