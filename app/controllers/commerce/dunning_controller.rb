module Commerce
  class DunningController < ApplicationController
    allow_unauthenticated_access
    before_action :set_account
    before_action :set_payment
    before_action :set_subscription
    before_action :set_payment_method
    before_action :authorize_dunning_session
    layout "checkout"

    def resolve_payment
      # if the payment is already resolved, redirect to the subscription page
      if @payment.status == "resolved"
        flash[:notice] = t("commerce.dunning.payment_already_resolved_notice", default: "Payment already resolved")
        redirect_to subscription_path(@account.slug, @subscription)
      end
    end

    def resolve_with_new_method
      render turbo_stream: turbo_stream.update("resolve_payment", partial: "commerce/dunning/new_payment_method_form", locals: { payment: @payment, payment_method: @payment_method })
    end

    def resolve_with_current_method
      render turbo_stream: turbo_stream.update("resolve_payment", partial: "commerce/dunning/pay_with_current_method", locals: { payment: @payment })
    end

    def create_setup_intent_for_resolve_payment
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

    def retry_payment
      # Check if the token is valid
      if @payment.resolve_token != params[:token]
        render json: { success: false, error: t("commerce.dunning.invalid_token_error", default: "Invalid token") }, status: :unauthorized
        return
      end

      @new_payment_method_form = false

      begin
        # If a new payment method is being added
        if params[:payment_method_token].present? || params[:setup_intent].present?
          @new_payment_method_form = true

          # If we have a setup intent, retrieve the payment method ID from it
          if params[:setup_intent].present?
            setup_intent = Stripe::SetupIntent.retrieve(params[:setup_intent])
            payment_method_id = setup_intent.payment_method
          else
            payment_method_id = params[:payment_method_token]
          end

          # Check if this payment method already exists for this account
          existing_payment_method = @account.payment_methods.find_by(
            processor_payment_method_id: payment_method_id
          )

          if existing_payment_method
            @payment_method = existing_payment_method
          else
            # Retrieve the payment method from Stripe
            stripe_payment_method = Stripe::PaymentMethod.retrieve(payment_method_id)

            # Save the payment method to our database
            @payment_method = @account.payment_methods.create!(
              processor_payment_method_id: stripe_payment_method.id,
              brand: stripe_payment_method.card.brand,
              last4: stripe_payment_method.card.last4,
              expiration_month: stripe_payment_method.card.exp_month,
              expiration_year: stripe_payment_method.card.exp_year
            )
          end

          # Attach the payment method to the customer in Stripe
          Stripe::PaymentMethod.attach(
            @payment_method.processor_payment_method_id,
            { customer: @subscription.processor_customer_id }
          )

          # Set as default payment method for the subscription
          Stripe::Subscription.update(
            @subscription.processor_subscription_id,
            { default_payment_method: @payment_method.processor_payment_method_id }
          )

          # Update the subscription in our database
          @subscription.update!(payment_method: @payment_method)
        else
          # Use the existing payment method
          @payment_method = @subscription.payment_method
        end

        # Attempt to charge the payment
        charge = Stripe::PaymentIntent.create(
          {
            amount: @payment.amount,
            currency: @payment.currency,
            payment_method: @payment_method.processor_payment_method_id,
            customer: @subscription.processor_customer_id,
            confirm: true,
            off_session: true,
            metadata: {
              subscription_id: @subscription.id,
              payment_id: @payment.id
            }
          }
        )

        if charge.status == "succeeded"
          # Create a new payment record
          new_payment = @subscription.payments.create!(
            account_id: @account.id,
            amount: @payment.amount,
            status: "succeeded",
            processor_payment_id: charge.id,
            processor_customer_id: @subscription.processor_customer_id,
            payment_method_id: @payment_method.id,
          )

          # Mark the Stripe invoice as paid
          if @payment.processor_invoice_id.present?
            Stripe::Invoice.pay(@payment.processor_invoice_id)
          end

          # Update the subscription status
          @subscription.update!(status: "active")

          # Update the account subscription status
          @account.update!(subscription_status: "paying_subscription")

          # Get all other payments associated with this Stripe invoice and update them to resolved
          invoice_payments = @account.payments.where(processor_invoice_id: @payment.processor_invoice_id).where.not(id: @payment.id)
          invoice_payments.each do |payment|
            payment.update!(
              status: "resolved",
              resolved_at: Time.current,
              resolved_by_payment_id: new_payment.id
            )
          end

        else
          @error_message = t("commerce.dunning.unknown_error", default: "Unknown error")
        end

        respond_to do |format|
          format.turbo_stream
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Error processing payment: #{e.message}"
        @error_message = e.message

        respond_to do |format|
          format.turbo_stream
        end
      end
    end

    private

    def set_account
      @account = Account.find_by(slug: params[:account_slug])
    end

    def set_payment
      @payment = @account.payments.find(params[:id])
    end

    def set_subscription
      @subscription = @payment.subscription
    end

    def set_payment_method
      @payment_method = @subscription.payment_method
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

    def authorize_dunning_session
      # If the token is invalid, redirect to the subscription page
      if @payment.resolve_token != params[:token]
        redirect_to subscription_path(@account.slug, @subscription), alert: t("commerce.dunning.invalid_token_alert", default: "Invalid token")
      end

      # If the payment is already resolved, redirect to the subscription page
      if @payment.status == "resolved"
        redirect_to subscription_path(@account.slug, @subscription), alert: t("commerce.dunning.payment_already_resolved_alert", default: "Payment has already been resolved")
      end
    end
  end
end
