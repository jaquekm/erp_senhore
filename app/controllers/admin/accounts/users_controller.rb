# frozen_string_literal: true

module Admin
  module Accounts
    class UsersController < Admin::BaseController
      before_action :set_account
      before_action :set_user, only: %i[edit update destroy]

      def new
        @user = @account.users.new
      end

      def create
        @user = @account.users.new(user_params)
        @user.role = :member
        add_seat_limit_error unless @account.seats_available?

        if @user.errors.none? && @user.save
          redirect_to admin_account_path(@account), notice: 'Usuário criado com sucesso.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        attrs = user_params
        attrs = attrs.except(:password) if attrs[:password].blank?
        attrs = attrs.except(:active) if @user.owner? # the account owner can't be locked out this way

        if @user.update(attrs)
          redirect_to admin_account_path(@account), notice: 'Usuário atualizado com sucesso.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @user.owner?
          redirect_to admin_account_path(@account), alert: 'Não é possível remover o usuário titular da conta.'
          return
        end

        @user.destroy
        redirect_to admin_account_path(@account), notice: 'Usuário removido com sucesso.'
      end

      private

      def add_seat_limit_error
        @user.errors.add(:base, "Limite de #{@account.max_users} usuário(s) atingido para esta conta. " \
                                 'Aumente o limite de usuários antes de adicionar mais um.')
      end

      def set_account
        @account = Account.find(params[:account_id])
      end

      def set_user
        @user = @account.users.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :password, :first_name, :last_name, :active)
      end
    end
  end
end
