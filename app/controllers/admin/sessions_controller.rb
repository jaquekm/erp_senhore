# frozen_string_literal: true

module Admin
  # Devise generates this off Devise::SessionsController, which (like every
  # Devise controller) inherits from the top-level ApplicationController.
  # That controller requires a signed-in client User for every request, so
  # it has to be skipped here -- an admin visiting /admin/sign_in is never
  # signed in as a client User.
  class SessionsController < Devise::SessionsController
    skip_before_action :authenticate_user!, raise: false

    layout 'admin'

    private

    def after_sign_in_path_for(_resource)
      admin_accounts_path
    end

    def after_sign_out_path_for(_resource)
      new_admin_user_session_path
    end
  end
end
