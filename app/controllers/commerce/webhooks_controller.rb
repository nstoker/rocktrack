module Commerce
  class WebhooksController < ApplicationController
    # Skip authentication and CSRF protection for webhooks
    skip_before_action :verify_authenticity_token, raise: false
    allow_unauthenticated_access

    # Remove the set_account skip since it doesn't exist
    # skip_before_action :set_account

    before_action :verify_stripe_signature

    def stripe
      Rails.logger.info "=== Stripe Webhook Request ==="
      Rails.logger.info "Event Type: #{params[:type]}"

      # Only process events that happen after subscription creation
      case params[:type]
      when "invoice.payment_succeeded"
        handle_invoice_payment_succeeded(params[:data][:object])
      when "invoice.payment_failed"
        handle_invoice_payment_failed(params[:data][:object])
      when "customer.subscription.deleted"
        handle_subscription_cancelled(params[:data][:object])
      when "customer.subscription.updated"
        handle_subscription_updated(params[:data][:object])
      else
        Rails.logger.info "Ignoring pre-subscription event: #{params[:type]}"
      end

      head :ok
    end

    private

    def verify_stripe_signature
      head :bad_request unless request.env["HTTP_STRIPE_SIGNATURE"].present?
    end

    def handle_invoice_payment_succeeded(invoice)
      Rails.logger.info "=== Processing invoice.payment_succeeded ==="
      Rails.logger.info "Invoice ID: #{invoice['id']}"

      if invoice["subscription"].nil? # Skip if not a subscription invoice
        return
      end
      if invoice["amount_paid"] == 0 # Skip $0 trial invoices - these are handled during subscription creation
        return
      end

      # Try to find the subscription
      subscription = ::Commerce::Subscription.find_by(processor_subscription_id: invoice["subscription"])
      unless subscription # Skip if subscription not found
        return
      end

      # Only process if the subscription is active or trialing
      unless [ "active", "trialing" ].include?(subscription.status)
        return
      end

      # Create a payment record
      payment = ::Commerce::Payment.create!(
        account: subscription.account,
        currency: invoice["currency"],
        subscription_id: subscription.id,
        purchase_id: subscription.purchase.id,
        processor_payment_id: invoice["payment_intent"],
        processor_customer_id: invoice["customer"],
        processor_invoice_id: invoice["id"],
        payment_method_id: find_payment_method_id(invoice["payment_intent"]),
        amount: invoice["amount_paid"],
        status: "succeeded"
      )

      # Update subscription status
      subscription.update!(
        status: "active",
        current_period_end: Time.at(invoice["lines"]["data"][0]["period"]["end"])
      )
    end

    def handle_invoice_payment_failed(invoice)
      Rails.logger.info "=== Processing invoice.payment_failed ==="
      Rails.logger.info "Invoice ID: #{invoice['id']}"

      if invoice["subscription"].nil? # Skip if not a subscription invoice
        return
      end
      if invoice["amount_due"] == 0 # Skip $0 trial invoices - these are handled during subscription creation
        return
      end

      # Try to find the subscription
      subscription = ::Commerce::Subscription.find_by(processor_subscription_id: invoice["subscription"])

      unless subscription # Skip if subscription not found
        return
      end

      # Create a payment record
      payment = ::Commerce::Payment.create!(
        account: subscription.account,
        currency: invoice["currency"],
        subscription_id: subscription.id,
        processor_payment_id: invoice["payment_intent"],
        processor_customer_id: invoice["customer"],
        processor_invoice_id: invoice["id"],
        payment_method_id: subscription.payment_method_id,
        amount: invoice["amount_due"],
        status: "failed",
        resolve_token: SecureRandom.hex(16)
      )

      # Update subscription status
      subscription.update!(
        status: "past_due"
      )

      # Update the account subscription status
      subscription.account.update!(
        subscription_status: "subscription_past_due"
      )

      # Notify the account owner
      CommerceMailer.dunning_email(payment).deliver_later
    end

    def handle_subscription_cancelled(subscription)
      Rails.logger.info "=== Processing subscription_cancelled ==="
      Rails.logger.info "Subscription ID: #{subscription['id']}"

      # Try to find the subscription
      subscription_record = ::Commerce::Subscription.find_by(processor_subscription_id: subscription["id"])

      unless subscription_record # Skip if subscription not found
        return
      end

      subscription_record.update!(
        status: :cancelled,
        cancellation_date: Time.current,
        cancellation_reason: "Cancelled in Stripe"
      )

      # Update the account subscription status
      subscription_record.account.update!(
        subscription_status: "cancelled_subscription"
      )

      # Notify the account owner
      CommerceMailer.admin_subscription_cancellation_initiated(subscription_record).deliver_later
    end

    def handle_subscription_updated(subscription)
      Rails.logger.info "=== Processing subscription_updated ==="
      Rails.logger.info "Subscription ID: #{subscription['id']}"

      # Try to find the subscription
      subscription_record = ::Commerce::Subscription.find_by(processor_subscription_id: subscription["id"])
      unless subscription_record # Skip if subscription not found
        return
      end

      # Map Stripe status to our enum values
      status = case subscription["status"]
      when "active"
        "active"
      when "trialing"
        "trialing"
      when "incomplete", "incomplete_expired", "past_due", "unpaid"
        "past_due"
      when "canceled"
        "cancelled"
      else
        "active"  # Default to active for any other status
      end

      subscription_params = {}
      update_subscription = false

      if subscription["current_period_end"].present?
        subscription_params[:current_period_end] = Time.at(subscription["current_period_end"])
        update_subscription = true
      end

      if status.present?
        subscription_params[:status] = status
        update_subscription = true
      end

      # Handle plan change if the price_id has changed
      if subscription["items"].present? && subscription["items"]["data"].present? && subscription["items"]["data"].first.present?
        new_price_id = subscription["items"]["data"].first["price"]["id"]

        # Check if we already have this price in our database
        price = ::Commerce::Price.find_by(processor_price_id: new_price_id)

        if price.nil?
          # Fetch the price details from Stripe
          stripe_price = Stripe::Price.retrieve(new_price_id)

          # Check if we have the product in our database
          product = ::Commerce::Product.find_by(processor_product_id: stripe_price.product)

          if product.nil?
            # Fetch the product details from Stripe
            stripe_product = Stripe::Product.retrieve(stripe_price.product)

            # Create the product
            product = ::Commerce::Product.create!(
              name: stripe_product.name,
              processor_product_id: stripe_product.id
            )

            # Generate slug for the product
            product.generate_slug_by_name
            product.save!
          end

          # Create the price
          price = ::Commerce::Price.create!(
            name: new_price_id, # Use the Stripe price ID as the name
            processor_price_id: new_price_id,
            product_id: product.id,
            amount: stripe_price.unit_amount,
            recurring: stripe_price.recurring.present?,
            recurring_interval: map_stripe_interval_to_enum(stripe_price.recurring&.interval),
            trial_days: stripe_price.recurring&.trial_period_days || 0
          )

          # Generate slug for the price
          price.generate_slug_by_name
          price.save!
        end

        # Update the subscription with the new price
        subscription_params[:price_id] = price.id
        update_subscription = true
      end

      if update_subscription
        subscription_record.update!(subscription_params)
      end
    end

    def find_payment_method_id(payment_intent_id)
      # Retrieve the payment intent from Stripe to get the payment method ID
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

      # Find the payment method in our database that matches the Stripe payment method ID
      payment_method = ::Commerce::PaymentMethod.find_by(processor_payment_method_id: payment_intent.payment_method)

      # Return the payment method ID if found, otherwise nil
      payment_method&.id
    end

    def map_stripe_interval_to_enum(stripe_interval)
      case stripe_interval
      when "day"
        :day
      when "week"
        :week
      when "month"
        :month
      when "quarter"
        :quarter
      when "year"
        :year
      else
        :day # Default to day if unknown
      end
    end
  end
end
