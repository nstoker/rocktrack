module Commerce
  class PurchasesController < ApplicationController
    include Pagy::Backend

    before_action :set_account
    before_action :authorize_account_admin_user

    def index
      @purchases = @account.purchases.order(created_at: :desc)
    end

    def show
      @purchase = @account.purchases.find(params[:id])
    end

    private

    def set_account
      @account = Account.find_by!(slug: params[:account_slug])
    end
  end
end
