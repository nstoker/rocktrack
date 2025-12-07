module Commerce
  class BillingController < ApplicationController
    before_action :set_account
    before_action :authorize_account_admin_user

    def overview
    end

    private

    def set_account
      @account = Account.find_by!(slug: params[:account_slug])
    end
  end
end
