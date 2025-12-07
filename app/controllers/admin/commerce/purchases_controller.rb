module Admin
  module Commerce
    class PurchasesController < AdminController
      include Pagy::Backend

      before_action :set_purchase, only: [ :show, :destroy ]

      def index
        @purchases = ::Commerce::Purchase.all.order(created_at: :desc)

        @pagy, @purchases = pagy(@purchases, items: 20)
      end

      def show
        @account = @purchase.account
      end

      def destroy
        @purchase.destroy
        redirect_to admin_purchases_path, notice: "Purchase was successfully deleted."
      end

      private

      def set_purchase
        @purchase = ::Commerce::Purchase.find(params[:id])
      end
    end
  end
end
