# frozen_string_literal: true

module Admin
  class AccountsController < BaseController
    before_action :set_account, only: %i[show edit update toggle_feature]

    def index
      @accounts = Account.includes(:user).order(:company_name)
    end

    def new
      @account = Account.new
    end

    def create
      owner = build_owner

      if owner.save
        owner.owned_account.update!(seat_limit_params)
        redirect_to admin_account_path(owner.owned_account), notice: 'Conta criada com sucesso.'
      else
        @account = Account.new(account_params.slice(:company_name, :max_users, :max_concurrent_sessions))
        flash.now[:alert] = owner.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @modules = Feature.order(:feature_key)
      @account_features_by_feature_id = @account.account_features.index_by(&:feature_id)
      @users = @account.users.order(role: :asc, email: :asc)
    end

    def edit; end

    def update
      if @account.update(account_params.slice(:company_name, :max_users, :max_concurrent_sessions))
        redirect_to admin_account_path(@account), notice: 'Conta atualizada com sucesso.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_feature
      enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
      Services::AccountFeatureToggler.call(account: @account, feature_key: params[:feature_key], enabled: enabled)
      redirect_to admin_account_path(@account), notice: 'Módulos atualizados.'
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      redirect_to admin_account_path(@account), alert: "Não foi possível atualizar o módulo: #{e.message}"
    end

    private

    def build_owner
      User.new(email: account_params[:owner_email], password: account_params[:owner_password],
               company_name: account_params[:company_name], role: :owner)
    end

    def seat_limit_params
      {
        max_users: account_params[:max_users].presence || 1,
        max_concurrent_sessions: account_params[:max_concurrent_sessions].presence || 1
      }
    end

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:company_name, :owner_email, :owner_password, :max_users,
                                      :max_concurrent_sessions)
    end
  end
end
