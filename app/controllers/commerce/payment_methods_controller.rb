module Commerce
  class PaymentMethodsController < ApplicationController
    include Pagy::Backend

    before_action :set_account
    before_action :authorize_account_admin_user
    before_action :set_payment_method, only: [ :destroy, :make_default ]

    def index
      @payment_methods = @account.payment_methods
      @pagy, @payment_methods = pagy(@payment_methods, items: 20)
    end

    def new
      @payment_method = @account.payment_methods.new
    end

    def create_setup_intent
      begin
        # Create or retrieve Stripe customer
        customer = find_or_create_stripe_customer

        # Create a setup intent
        setup_intent = Stripe::SetupIntent.create(
          customer: customer.id,
          payment_method_types: [ "card" ],
          usage: "off_session"
        )

        render json: {
          client_secret: setup_intent.client_secret
        }
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error in create_setup_intent: #{e.class.name} - #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    def process_create_payment_method
      if params[:setup_intent] && params[:redirect_status] == "succeeded"
        setup_intent_id = params[:setup_intent].split("_secret_").first
        setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)

        # Get the payment method details
        payment_method = Stripe::PaymentMethod.retrieve(setup_intent.payment_method)
        card_details = payment_method.card

        # Create payment method record
        payment_method_record = @account.payment_methods.create!(
          processor_payment_method_id: payment_method.id,
          processor_customer_id: setup_intent.customer,
          brand: card_details.brand,
          last4: card_details.last4,
          expiration_month: card_details.exp_month,
          expiration_year: card_details.exp_year,
          default: true
        )

        # Set as default payment method in Stripe
        Stripe::Customer.update(
          setup_intent.customer,
          { invoice_settings: { default_payment_method: payment_method.id } }
        )

        # Find all subscriptions with null payment method and associate them with the new payment method
        @account.subscriptions.where(payment_method_id: nil).find_each do |subscription|
          # Update the subscription in our database
          subscription.update!(payment_method_id: payment_method_record.id)

          # Update the subscription in Stripe if it has a processor_subscription_id
          if subscription.processor_subscription_id.present?
            begin
              Stripe::Subscription.update(
                subscription.processor_subscription_id,
                { default_payment_method: payment_method.id }
              )
            rescue Stripe::StripeError => e
              Rails.logger.error "Error updating Stripe subscription #{subscription.processor_subscription_id}: #{e.message}"
            end
          end
        end

        redirect_to payment_methods_path(@account.slug), notice: t("commerce.payment_methods.created_notice", default: "Payment method created")
      else
        redirect_to new_payment_method_path(@account.slug), alert: t("commerce.payment_methods.verification_failed_alert", default: "Payment method verification failed. Please try again.")
      end
    end

    def make_default
      begin
        # Update the payment method in our database
        @payment_method.update!(default: true)

        # Update the default payment method in Stripe
        if @payment_method.processor_payment_method_id.present? && @account.processor_customer_id.present?
          Stripe::Customer.update(
            @account.processor_customer_id,
            { invoice_settings: { default_payment_method: @payment_method.processor_payment_method_id } }
          )
        end

        redirect_to payment_methods_path(@account.slug), notice: t("commerce.payment_methods.made_default_notice", default: "Payment method made default")
      rescue Stripe::StripeError => e
        Rails.logger.error "Error updating Stripe customer default payment method: #{e.message}"
        redirect_to payment_methods_path(@account.slug), alert: t("commerce.payment_methods.failed_update_default_alert", default: "Failed to update default payment method: #{e.message}", error: e.message)
      end
    end

    def destroy
      was_default = @payment_method.default?

      begin
        # Try to detach the payment method from Stripe customer if it exists
        if @payment_method.processor_payment_method_id.present?
          begin
            Stripe::PaymentMethod.detach(@payment_method.processor_payment_method_id)
          rescue Stripe::InvalidRequestError => e
            # If the payment method is already detached or doesn't exist, log it and continue
            Rails.logger.info "Payment method #{@payment_method.processor_payment_method_id} could not be detached: #{e.message}"
          end
        end

        # Delete the payment method record
        @payment_method.destroy

        # If this was the default payment method, make the most recent one the default
        if was_default
          most_recent_payment_method = @account.payment_methods.order(created_at: :desc).first
          if most_recent_payment_method
            most_recent_payment_method.update!(default: true)

            # Try to update Stripe customer's default payment method if we have a valid customer ID
            if @account.processor_customer_id.present? && most_recent_payment_method.processor_payment_method_id.present?
              begin
                Stripe::Customer.update(
                  @account.processor_customer_id,
                  { invoice_settings: { default_payment_method: most_recent_payment_method.processor_payment_method_id } }
                )
              rescue Stripe::InvalidRequestError => e
                # If the customer doesn't exist or other Stripe error, log it and continue
                Rails.logger.info "Could not update Stripe customer default payment method: #{e.message}"
              end
            end
          end
        end

        redirect_to payment_methods_path(@account.slug), notice: t("commerce.payment_methods.deleted_notice", default: "Payment method deleted successfully")
      rescue => e
        Rails.logger.error "Error in destroy: #{e.class.name} - #{e.message}"
        redirect_to payment_methods_path(@account.slug), alert: t("commerce.payment_methods.delete_error_alert", default: "Error deleting payment method: #{e.message}", error: e.message)
      end
    end

    private

    def set_account
      @account = Account.find_by!(slug: params[:account_slug])
    end

    def set_payment_method
      @payment_method = @account.payment_methods.find(params[:id])
    end

    def find_or_create_stripe_customer
      if @account.processor_customer_id.present?
        Stripe::Customer.retrieve(@account.processor_customer_id)
      else
        customer = Stripe::Customer.create(
          email: current_user.email_address,
          metadata: {
            account_id: @account.id
          }
        )
        @account.update!(processor_customer_id: customer.id)
        customer
      end
    end
  end
end
