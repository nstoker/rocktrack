module Admin
  module Commerce
    class PaymentsController < AdminController
      include Pagy::Backend

      before_action :set_payment, only: [ :show, :destroy ]

      def index
        @payments = ::Commerce::Payment.all.order(created_at: :desc)

        @pagy, @payments = pagy(@payments, items: 20)
      end

      def show
        @account = @payment.account
      end

      def destroy
        @payment.destroy
        redirect_to admin_payments_path, notice: "Payment was successfully deleted."
      end

      private

      def set_payment
        @payment = ::Commerce::Payment.find(params[:id])
      end
    end
  end
end
