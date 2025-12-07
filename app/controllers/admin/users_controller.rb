module Admin
  class UsersController < AdminController
    def index
      @users = User.all.order(created_at: :desc)
      @pagy, @users = pagy(@users, items: 20)
    end

    def show
      @user = User.find(params[:id])
    end

    def impersonate_user
      impersonate User.find(params[:id])
      redirect_to root_url
    end

    def stop_impersonating_user
      stop_impersonating
      redirect_to admin_user_path(id: params[:id])
    end
  end
end
