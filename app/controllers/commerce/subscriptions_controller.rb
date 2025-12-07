module Commerce
  class SubscriptionsController < ApplicationController
    before_action :set_account
    before_action :authorize_account_admin_user
    before_action :set_subscription

    def show
    end

    def edit_payment_method
      render turbo_stream: turbo_stream.update("payment_method", partial: "commerce/subscriptions/update_payment_method_form")
    end

    def update_payment_method
      payment_method = @account.payment_methods.find(params[:payment_method_id])

      begin
        # Update the subscription in Stripe
        if @subscription.processor_subscription_id.present?
          Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            { default_payment_method: payment_method.processor_payment_method_id }
          )
        end

        # Update the subscription in our database
        @subscription.update!(payment_method: payment_method)

        # Render the updated payment method partial
        render turbo_stream: turbo_stream.update("payment_method", partial: "commerce/subscriptions/payment_method", locals: { subscription: @subscription })
      rescue Stripe::StripeError => e
        Rails.logger.error "Error updating Stripe subscription: #{e.message}"
        render turbo_stream: turbo_stream.update("payment_method",
          partial: "commerce/subscriptions/update_payment_method_form",
          locals: { error: "Failed to update payment method: #{e.message}" })
      end
    end

    def edit_plan
      unless ::Commerce::Plan.active.any?
        redirect_to billing_overview_path(@account.slug), alert: t("commerce.subscriptions.no_plans_available_alert", default: "No plans available.")
      end

      @plans = ::Commerce::Plan.active
      @current_plan = @subscription.plan
      @current_price = @subscription.price
      @current_interval = @current_price == @current_plan.price_a ? "a" : "b"
    end

    def update
      new_price = ::Commerce::Price.find(params[:new_price_id])

      begin
        # Update the subscription in Stripe
        if @subscription.processor_subscription_id.present?
          # First retrieve the subscription to get the item ID
          stripe_subscription = Stripe::Subscription.retrieve(@subscription.processor_subscription_id)
          item_id = stripe_subscription.items.data.first.id

          Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            {
              items: [ {
                id: item_id,
                price: new_price.processor_price_id
              } ]
            }
          )
        end

        # Update the subscription in our database
        @subscription.update!(price: new_price)

        flash[:notice] = t("commerce.subscriptions.update_plan_success_notice", default: "Successfully updated your plan")
        redirect_to billing_overview_path(@account.slug)
      rescue Stripe::StripeError => e
        Rails.logger.error "Error updating Stripe subscription: #{e.message}"
        flash[:error] = e.message
        redirect_to edit_plan_path(@account.slug, @subscription), alert: t("commerce.subscriptions.update_plan_error_alert", default: "Something went wrong. Please try again. #{e.message}", error: e.message)
      rescue => e
        Rails.logger.error "Error updating subscription: #{e.message}"
        redirect_to edit_plan_path(@account.slug, @subscription), alert: "Something went wrong. Please try again. #{e.message}"
      end
    end

    def cancel; end

    def process_cancellation
      begin
        # Cancel the subscription in Stripe at period end
        if @subscription.processor_subscription_id.present?
          stripe_subscription = Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            { cancel_at_period_end: true }
          )

          # Update the subscription in our database
          @subscription.update!(
            cancellation_reason: params[:commerce_subscription][:cancellation_reason],
            cancellation_date: Time.at(stripe_subscription.items.data[0].current_period_end)
          )

          # Send notification email
          CommerceMailer.admin_subscription_cancellation_initiated(@subscription).deliver_later

          flash[:notice] = t("commerce.subscriptions.cancellation_notice", default: "Your subscription will be cancelled at the end of this billing cycle.")
          redirect_to subscription_path(@account.slug, @subscription)
        else
          flash[:error] = t("commerce.subscriptions.not_found_in_stripe_error", default: "Subscription not found in Stripe.")
          redirect_to subscription_path(@account.slug, @subscription)
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Error cancelling Stripe subscription: #{e.message}"
        flash[:error] = t("commerce.subscriptions.failed_cancel_error", default: "Failed to cancel subscription: #{e.message}", error: e.message)
        redirect_to subscription_path(@account.slug, @subscription)
      end
    end

    def resume
      begin
        # Remove scheduled cancellation in Stripe
        if @subscription.processor_subscription_id.present?
          Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            { cancel_at_period_end: false }
          )
        end

        # Update the subscription in our database
        @subscription.update!(
          cancellation_date: nil,
          cancellation_reason: nil
        )

        flash[:notice] = t("commerce.subscriptions.resumed_notice", default: "Your subscription has been resumed and will continue after the current billing period.")
        redirect_to subscription_path(@account.slug, @subscription)
      rescue Stripe::StripeError => e
        Rails.logger.error "Error resuming Stripe subscription: #{e.message}"
        flash[:error] = t("commerce.subscriptions.failed_resume_error", default: "Failed to resume subscription: #{e.message}", error: e.message)
        redirect_to subscription_path(@account.slug, @subscription)
      end
    end

    private

    def set_account
      @account = Account.find_by(slug: params[:account_slug])
    end

    def set_subscription
      @subscription = @account.subscriptions.find(params[:id])
    end
  end
end
