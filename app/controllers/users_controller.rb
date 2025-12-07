class UsersController < ApplicationController
  include ApplicationHelper
  before_action :set_user

  def edit
    @page_title = t("authentication.users.edit_profile_title", default: "Edit Profile")
  end

  def manage_password
    @page_title = t("authentication.users.manage_password_title", default: "Manage Password")
  end

  def update_profile
    if @user.update(user_profile_params)
      redirect_to edit_user_profile_path, notice: t("authentication.users.profile_updated", default: "Profile updated successfully")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.authenticate(user_password_params[:current_password])
      if @user.update(user_password_params.except(:current_password))
        redirect_to manage_password_path, notice: t("authentication.users.password_updated", default: "Password updated successfully")
      else
        render :manage_password, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = t("authentication.users.current_password_incorrect", default: "Current password is incorrect")
      render :manage_password, status: :unprocessable_entity
    end
  end

  # Remove the user's avatar and redirect to the edit profile page with a success notice.
  def remove_avatar
    @user.avatar.purge
    redirect_to edit_user_profile_path, notice: t("authentication.users.avatar_removed", default: "Avatar removed successfully.")
  end

  private

  def user_profile_params
    params.require(:user).permit(:email_address,
                                 :avatar,
                                 :timezone,
                                 :first_name,
                                 :last_name)
  end

  def user_password_params
    params.require(:user).permit(:current_password,
                                 :password,
                                 :password_confirmation)
  end

  def set_user
    @user = current_user
  end
end
