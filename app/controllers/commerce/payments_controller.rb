module Commerce
  class PaymentsController < ApplicationController
    include Pagy::Backend

    before_action :set_account
    before_action :authorize_account_admin_user

    def index
      @payments = @account.payments

      @pagy, @payments = pagy(@payments)
    end

    def show
      @payment = current_account.payments.find(params[:id])
    end

    private

    def set_account
      @account = Account.find_by!(slug: params[:account_slug])
    end
  end
end
