# frozen_string_literal: true

# Lets a controller declare which module it belongs to, so a client whose
# account doesn't have that module enabled is blocked at the controller
# level too -- not just hidden from the sidebar. This is the security half
# of module gating: hiding a menu item is cosmetic, this is what actually
# stops direct URL access.
module FeatureGate
  extend ActiveSupport::Concern

  included do
    helper_method :feature_enabled?
  end

  class_methods do
    def requires_feature(feature_key, **options)
      before_action(options) { require_feature!(feature_key) }
    end
  end

  private

  def feature_enabled?(feature_key)
    current_account.present? && current_account.feature_enabled?(feature_key)
  end

  def require_feature!(feature_key)
    return if feature_enabled?(feature_key)

    message = 'Este módulo não está liberado para a sua conta. Fale com o administrador para liberá-lo.'
    # Rendered in place (never redirected) so this can't loop: the target
    # page for a redirect could itself belong to a disabled module.
    # html/turbo_stream listed first so an ambiguous Accept header (e.g.
    # `*/*`, sent by a bare curl request or some non-browser clients)
    # prefers the page over JSON -- this is a user-facing block, not an
    # API error. A turbo_stream request just gets the same page: Turbo
    # renders any HTML response as a full visit when it isn't itself a
    # <turbo-stream> document.
    respond_to do |format|
      format.any(:html, :turbo_stream) { render 'shared/module_disabled', status: :forbidden, locals: { message: } }
      format.json { render json: { error: message }, status: :forbidden }
    end
  end
end
