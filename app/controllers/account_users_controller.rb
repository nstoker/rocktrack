class AccountUsersController < ApplicationController
  include Pagy::Backend
  before_action :set_account
  before_action :authorize_user
  before_action :set_account_user, only: [ :edit, :update, :destroy ]

  def index
    @account_users = @account.account_users.includes(:user)
    @pagy, @account_users = pagy(@account_users, items: 12)
  end

  def edit
  end

  def update
    if @account_user.update(account_user_params)
      is_me = current_user.id == @account_user.user.id
      notice_message = is_me ? t("teams.account_users_controller.role_updated", default: "Your role has been updated.") : t("teams.account_users_controller.role_updated_other", name: @account_user.user.name, default: "Updated %{name}'s role.")
      if is_me && current_user.account_admin?(@account)
        redirect_to edit_account_user_path(@account, @account_user.id), notice: notice_message
      else
        redirect_to root_path(@account), notice: notice_message
      end
    else
      render :edit
    end
  end

  def destroy
    is_me = current_user.id == @account_user.user.id
    @account_user.destroy
    notice_message = is_me ? t("teams.account_users_controller.removed_self", team: @account.name, default: "You've been removed from the %{team} team.") : t("teams.account_users_controller.removed_other", name: @account_user.user.name, team: @account.name, default: "Removed %{name} from the %{team} team.")
    redirect_to root_path, notice: notice_message
  end

  private

  def set_account
    @account = Account.find_by!(slug: params[:account_slug])
  end

  def set_account_user
    @account_user = @account.account_users.find(params[:id])
  end

  def account_user_params
    params.require(:account_user).permit(:role)
  end

  def authorize_user
    account_user = current_user.account_users.find_by(account: @account)

    unless account_user&.role == "admin"
      flash[:error] = t("teams.account_users_controller.no_permission", default: "You don't have permission to do that.")
      redirect_to accounts_path
    end
  end
end
