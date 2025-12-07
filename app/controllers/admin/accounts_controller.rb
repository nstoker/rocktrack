module Admin
  class AccountsController < AdminController
    def index
      @accounts = Account.all.order(created_at: :desc)
      @pagy, @accounts = pagy(@accounts, items: 20)
    end

    def show
      @account = Account.find(params[:id])
    end
  end
end
