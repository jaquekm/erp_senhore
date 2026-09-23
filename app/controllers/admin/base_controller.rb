# frozen_string_literal: true

module Admin
  # Deliberately does NOT inherit from the app's ApplicationController:
  # admins are a separate login (AdminUser) that manages every client
  # account, so none of the client-tenant machinery (ActsAsTenant scoping,
  # per-account feature gating, concurrent-session limits) belongs here.
  class BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
    protect_from_forgery with: :exception

    before_action :authenticate_admin_user!

    layout 'admin'
  end
end
