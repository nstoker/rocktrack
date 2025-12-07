module Admin
  module Commerce
    class SubscriptionsController < AdminController
      include Pagy::Backend

      before_action :set_subscription, only: [ :show, :cancel, :destroy ]

      def index
        @subscriptions = ::Commerce::Subscription.all.order(created_at: :desc)

        @pagy, @subscriptions = pagy(@subscriptions, items: 20)
      end

      def show
        @account = @subscription.account
      end

      def cancel
        begin
          # Cancel the subscription in Stripe at period end
          Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            { cancel_at_period_end: true }
          )

          # Update the subscription record
          @subscription.update(
            cancellation_reason: "Cancelled by admin (#{current_user.name})",
            cancellation_date: @subscription.current_period_end
          )

          redirect_to admin_subscription_path(@subscription), notice: "Subscription cancellation has been initiated."
        rescue Stripe::InvalidRequestError => e
          if e.message.include?("No such subscription")
            redirect_to admin_subscription_path(@subscription), alert: "Could not find subscription in Stripe. The subscription may have already been cancelled."
          else
            redirect_to admin_subscription_path(@subscription), alert: "An error occurred while cancelling the subscription: #{e.message}"
          end
        end
      end

      def destroy
        @subscription.destroy
        redirect_to admin_subscriptions_path, notice: "Subscription was successfully deleted."
      end

      private

      def set_subscription
        @subscription = ::Commerce::Subscription.find(params[:id])
      end
    end
  end
end
