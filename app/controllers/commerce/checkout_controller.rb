require "ostruct"

module Commerce
  class CheckoutController < ApplicationController
    allow_unauthenticated_access(except: [ :create_payment_intent ])
    include ApplicationHelper

    before_action :set_product, except: [ :process_checkout, :checkout_success, :validate_coupon ]
    before_action :set_price, except: [ :process_checkout, :checkout_success, :validate_coupon ]

    layout :set_layout

    def checkout
      @error_message = params[:error]
    end

    def register_at_checkout
      @user = User.new(user_params)

      existing_user = User.find_by(email_address: @user.email_address)
      if existing_user && existing_user.authenticate(user_params[:password])
        start_new_session_for existing_user
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "payment", coupon: params[:coupon] }) }
        end
      elsif existing_user
        # User exists but password doesn't match
        @user.errors.add(:base, t("commerce.checkout.account_exists_error", default: "An account with this email already exists. Please use the login form."))
        render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "login", coupon: params[:coupon] })
      elsif @user.save
        start_new_session_for @user
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "payment", coupon: params[:coupon] }) }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def login_at_checkout
      if @user = User.authenticate_by(user_params)
        start_new_session_for @user
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "payment", coupon: params[:coupon] }) }
        end
      else
        # Create a new user object to hold the errors
        @user = User.new(email_address: user_params[:email_address])
        @user.errors.add(:base, t("commerce.checkout.invalid_login_error", default: "Invalid email or password"))

        render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "login", coupon: params[:coupon] })
      end
    end

    def switch_to_login
      render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "login" })
    end

    def switch_to_register
      render turbo_stream: turbo_stream.update("checkout_form", partial: "commerce/checkout/checkout_form", locals: { mode: "register" })
    end

    def switch_to_new_payment_method
      render turbo_stream: turbo_stream.update("payment_form", partial: "commerce/checkout/payment_form", locals: { price: @price, coupon: params[:coupon] })
    end

    def switch_to_existing_payment_method
      render turbo_stream: turbo_stream.update("payment_form", partial: "commerce/checkout/existing_payment_method", locals: { price: @price, coupon: params[:coupon] })
    end

    def create_payment_intent
      Rails.logger.info "=== Starting create_payment_intent ==="
      Rails.logger.info "Params: #{params.inspect}"

      unless @price
        Rails.logger.error "No price found for params: #{params.inspect}"
        render json: { error: "No price found" }, status: :unprocessable_entity
        return
      end

      # Find or create Stripe customer
      customer = find_or_create_stripe_customer

      # Get the payment method ID if provided
      payment_method_id = params[:payment_method_id]

      # If this is a subscription...
      if params[:is_subscription] == "true" || params[:is_subscription] == true
        Rails.logger.info "Processing subscription purchase"
        # If there's a trial period, create a setup intent

        if params[:trial_days].to_i > 0
          Rails.logger.info "Creating setup intent for trial subscription"
          begin
            # If a payment method ID is provided, look up the Stripe payment method ID
            if payment_method_id.present?
              payment_method = current_account.payment_methods.find_by(id: payment_method_id)
              if payment_method.nil?
                render json: { error: "Payment method not found" }, status: :unprocessable_entity
                return
              end
              payment_method_id = payment_method.processor_payment_method_id
            end

            setup_intent_metadata = {
              product_id: @product.id,
              price_id: @price.id
            }

            # Pass coupon promotion code to setup intent metadata if provided
            # This will be used in the process_checkout method to apply the coupon to the subscription that will be created
            if params[:coupon].present?
              promotion_code = get_promotion_code(params[:coupon])
              if promotion_code.present?
                setup_intent_metadata[:promotion_code_id] = promotion_code.id
              end
            end

            setup_intent = Stripe::SetupIntent.create({
              customer: customer.id,
              payment_method_types: [ "card" ],
              usage: "off_session",
              metadata: setup_intent_metadata
            })
            client_secret = setup_intent.client_secret
            is_setup_intent = true
          rescue Stripe::StripeError => e
            Rails.logger.error "Error creating setup intent: #{e.message}"
            render json: { error: e.message }, status: :unprocessable_entity
            return
          end
        else
          # This is a subscription with no trial period
          Rails.logger.info "Creating subscription without trial"

          begin
            subscription_params = {
              customer: customer.id,
              items: [ { price: @price.processor_price_id } ],
              payment_behavior: "default_incomplete",
              payment_settings: { save_default_payment_method: "on_subscription" },
              expand: [ "latest_invoice.confirmation_secret" ],
              metadata: {
                product_id: @product.id,
                price_id: @price.id
              }
            }

            # Apply coupon to subscription if provided
            if params[:coupon].present?
              promotion_code = get_promotion_code(params[:coupon])
              if promotion_code.present?
                subscription_params[:discounts] = [ { promotion_code: promotion_code.id } ]
              end
            end

            # If a payment method is selected, use it
            if payment_method_id.present?
              # Look up the Stripe payment method ID
              payment_method = current_account.payment_methods.find_by(id: payment_method_id)
              if payment_method.nil?
                render json: { error: "Payment method not found" }, status: :unprocessable_entity
                return
              end
              subscription_params[:default_payment_method] = payment_method.processor_payment_method_id
              subscription_params[:payment_behavior] = "error_if_incomplete"
            end

            subscription = Stripe::Subscription.create(subscription_params)
            client_secret = subscription.latest_invoice.confirmation_secret.client_secret
            is_setup_intent = false

            # Store the subscription ID in the payment intent's metadata
            payment_intent_id = subscription.latest_invoice.confirmation_secret.client_secret.split("_secret_").first
            payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
            payment_intent.metadata = { subscription_id: subscription.id }
            payment_intent.save
          rescue Stripe::StripeError => e
            Rails.logger.error "Error creating Stripe subscription: #{e.message}"
            render json: { error: e.message }, status: :unprocessable_entity
            return
          end
        end

      else # This is a one-time purchase...
        amount = @price.amount

        # If a coupon is present, calculate its amount off and adjust the payment_intent amount
        if params[:coupon].present?
          promotion_code = get_promotion_code(params[:coupon])
          if promotion_code.present?
            if promotion_code.coupon.percent_off.present?
              amount = (amount * (1 - promotion_code.coupon.percent_off.to_f / 100)).to_i
            elsif promotion_code.coupon.amount_off.present?
              amount = amount - promotion_code.coupon.amount_off
            end
          end
        end

        # Create a one-time payment intent
        payment_intent_params = {
          amount: amount,
          currency: "usd",
          customer: customer.id,
          automatic_payment_methods: {
            enabled: true
          },
          setup_future_usage: "off_session",
          metadata: {
            product_id: @product.id,
            price_id: @price.id
          }
        }

        # If a payment method is selected, use it
        if payment_method_id.present?
          # Look up the Stripe payment method ID
          payment_method = current_account.payment_methods.find_by(id: payment_method_id)
          if payment_method.nil?
            render json: { error: "Payment method not found" }, status: :unprocessable_entity
            return
          end
          payment_intent_params[:payment_method] = payment_method.processor_payment_method_id
          payment_intent_params[:confirm] = true
          payment_intent_params[:automatic_payment_methods] = { enabled: false }
          payment_intent_params[:payment_method_types] = [ "card" ]
        end

        payment_intent = Stripe::PaymentIntent.create(payment_intent_params)
        client_secret = payment_intent.client_secret
        is_setup_intent = false
      end

      render json: {
        client_secret: client_secret,
        is_setup_intent: is_setup_intent
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error in create_payment_intent: #{e.class.name} - #{e.message}"
      render json: {
        error: e.message,
        error_type: e.class.name,
        error_code: e.respond_to?(:code) ? e.code : nil,
        error_param: e.respond_to?(:param) ? e.param : nil
      }, status: :unprocessable_entity
    end

    def process_checkout
      # This request is made from checkout_controller.js after the Stripe transaction has completed.
      # Now we process the purchase and redirect...

      if params[:setup_intent] && params[:redirect_status] == "succeeded"
        # A subscription with a trial period was created, so a SetupIntent was used.

        # In the case of someone purchasing with an existing payment method via our form in existing_payment_method,
        # the setup_intent will be in the format of "setup_intent_<secret>".
        # So we need to extract the ID from the client secret.
        setup_intent_id = params[:setup_intent].split("_secret_").first

        # This is a trial subscription with a successful setup_intent
        setup_intent_or_payment_intent = Stripe::SetupIntent.retrieve(setup_intent_id)

        # Set product and price for subscription
        @product = Commerce::Product.find_by(id: setup_intent_or_payment_intent.metadata.product_id)
        @price = Commerce::Price.find_by(id: setup_intent_or_payment_intent.metadata.price_id)

        # Create the subscription with the payment method from the setup intent
        subscription_params = {
          customer: setup_intent_or_payment_intent.customer,
          items: [ { price: @price.processor_price_id } ],
          default_payment_method: setup_intent_or_payment_intent.payment_method,
          trial_end: (@price.trial_days.days.from_now).to_i,
          metadata: {
            product_id: @product.id,
            price_id: @price.id
          }
        }

        # Apply promotion code if it was in the setup intent metadata
        if setup_intent_or_payment_intent&.metadata&.respond_to?(:promotion_code_id) &&
           setup_intent_or_payment_intent.metadata.promotion_code_id.present?
          subscription_params[:discounts] = [ { promotion_code: setup_intent_or_payment_intent.metadata.promotion_code_id } ]
        end

        subscription = Stripe::Subscription.create(subscription_params)

        success = true
        options = { subscription: subscription }

      elsif params[:payment_intent] && params[:redirect_status] == "succeeded"
        # Either a subscription with no trial (and an immediate first charge)
        # Or a one-time purchase was made, so a PaymentIntent was used.

        # In the case of someone purchasing with an existing payment method via our form in existing_payment_method,
        # the payment_intent will be in the format of "payment_intent_<secret>".
        # So we need to extract the ID from the client secret.
        payment_intent_id = params[:payment_intent].split("_secret_").first

        # This is a one-time payment or non-trial subscription
        setup_intent_or_payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

        options = {}

        # Check if this payment intent is from a subscription by looking at the metadata
        if setup_intent_or_payment_intent.metadata && setup_intent_or_payment_intent.metadata["subscription_id"].present?
          # This is a subscription payment intent
          subscription = Stripe::Subscription.retrieve(setup_intent_or_payment_intent.metadata["subscription_id"])

          # Pass the subscription to the create_purchase_records method
          options[:subscription] = subscription

          # Set product and price for subscription
          @product = Commerce::Product.find_by(id: subscription.metadata["product_id"])
          @price = @product.prices.find_by(id: subscription.metadata["price_id"])
        else
          # This is a regular one-time purchase
          @product = Commerce::Product.find_by(id: setup_intent_or_payment_intent.metadata["product_id"])
          @price = @product.prices.find_by(id: setup_intent_or_payment_intent.metadata["price_id"])
        end

        success = true
      else # The transaction failed
        success = false
      end

      if success
        # Set the payment method as the default for the customer
        set_default_payment_method(setup_intent_or_payment_intent)

        # Create purchase records
        create_purchase_records(setup_intent_or_payment_intent, options)

        # Redirect to the success page
        redirect_to checkout_success_path
      else
        redirect_to checkout_path, alert: t("commerce.checkout.payment_verification_failed_alert", default: "Payment verification failed. Please contact support.")
      end
    end

    def checkout_success
      @account = current_account
    end

    def validate_coupon
      code = params[:code]

      begin
        # Search for the promotion code
        promotion_codes = Stripe::PromotionCode.list({
          code: code,
          active: true,
          limit: 1
        })

        if promotion_codes.data.empty?
          render json: { valid: false }
          return
        end

        promotion_code = promotion_codes.data.first
        coupon = promotion_code.coupon

        # Check if the coupon is valid and not expired
        valid = coupon.valid &&
                (coupon.redeem_by.nil? || coupon.redeem_by > Time.current.to_i) &&
                promotion_code.active

        if valid
          hash = { valid: true }
          hash[:success_message] = promotion_code&.metadata&.success_message if promotion_code&.metadata&.respond_to?(:success_message) && promotion_code&.metadata&.success_message.present?
          hash[:success_description] = promotion_code&.metadata&.success_description if promotion_code&.metadata&.respond_to?(:success_description) && promotion_code&.metadata&.success_description.present?
          hash[:custom_price_text] = promotion_code&.metadata&.custom_price_text if promotion_code&.metadata&.respond_to?(:custom_price_text) && promotion_code&.metadata&.custom_price_text.present?
          hash[:custom_append_text] = promotion_code&.metadata&.custom_append_text if promotion_code&.metadata&.respond_to?(:custom_append_text) && promotion_code&.metadata&.custom_append_text.present?
          hash[:percent_off] = coupon.percent_off if coupon.respond_to?(:percent_off)
          hash[:amount_off] = coupon.amount_off if coupon.respond_to?(:amount_off)

          render json: hash
        else
          render json: { valid: false }
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Error validating promotion code: #{e.class.name} - #{e.message}"
        Rails.logger.error "Error details: #{e.json_body}" if e.respond_to?(:json_body)
        Rails.logger.error "Error code: #{e.code}" if e.respond_to?(:code)
        Rails.logger.error "Error param: #{e.param}" if e.respond_to?(:param)
        Rails.logger.error "Error http_body: #{e.http_body}" if e.respond_to?(:http_body)
        Rails.logger.error "Error http_status: #{e.http_status}" if e.respond_to?(:http_status)
        render json: { valid: false, error: e.message }
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address,
                                  :password,
                                  :timezone,
                                  :coupon)
    end

    def set_layout
      if action_name == "checkout"
        "checkout"
      else
        "application"
      end
    end

    def set_product
      @product = if params[:product].present?
        Commerce::Product.find_by(slug: params[:product])
      end

      unless @product
        redirect_to root_path, alert: t("commerce.checkout.product_not_found_alert", default: "Product not found")
      end
    end

    def set_price
      @price = if params[:price].present?
                 @product.prices.find_by(slug: params[:price])
      else
                 @product.default_price
      end
    end

    def find_or_create_stripe_customer
      Rails.logger.debug "Finding or creating Stripe customer for account: #{current_account.inspect}"

      if current_account.processor_customer_id.present?
        Rails.logger.debug "Retrieving existing Stripe customer: #{current_account.processor_customer_id}"
        Stripe::Customer.retrieve(current_account.processor_customer_id)
      else
        Rails.logger.debug "Creating new Stripe customer for user: #{current_user.email_address}"
        customer = Stripe::Customer.create(
          email: current_user.email_address,
          metadata: {
            account_id: current_account.id,
            user_id: current_user.id
          }
        )
        Rails.logger.debug "Created Stripe customer: #{customer.id}"
        current_account.update(processor_customer_id: customer.id)
        customer
      end
    end

    def set_default_payment_method(setup_intent_or_payment_intent)
      # Determine the customer ID based on the type of intent
      customer_id = setup_intent_or_payment_intent.customer

      # Extract the payment method ID from the intent
      payment_method_id = setup_intent_or_payment_intent.payment_method

      # If we couldn't get a payment method ID from the intent, try to get it from the subscription
      if payment_method_id.nil? && setup_intent_or_payment_intent.is_a?(Stripe::SetupIntent)
        # Find the subscription associated with this setup intent
        subscriptions = Stripe::Subscription.list(customer: customer_id, limit: 1).data
        if subscriptions.any?
          subscription = subscriptions.first
          payment_method_id = subscription.default_payment_method
        end
      end

      # If we still couldn't get a payment method ID, log an error and return
      if payment_method_id.nil?
        Rails.logger.error "Could not determine payment method ID from intent or subscription"
        return
      end

      # First, ensure the payment method is attached to the customer
      begin
        # Try to attach the payment method to the customer
        Stripe::PaymentMethod.attach(
          payment_method_id,
          { customer: customer_id }
        )
        Rails.logger.info "Successfully attached payment method #{payment_method_id} to customer #{customer_id}"
      rescue Stripe::InvalidRequestError => e
        if e.message.include?("already attached")
          # Payment method is already attached, which is fine
          Rails.logger.info "Payment method #{payment_method_id} already attached to customer #{customer_id}"
        else
          # Some other error occurred
          Rails.logger.error "Error attaching payment method: #{e.message}"
          # We'll still try to set it as default, as it might be attached through another process
        end
      end

      # Now set the payment method as the default for the customer
      begin
        Stripe::Customer.update(
          customer_id,
          { invoice_settings: { default_payment_method: payment_method_id } }
        )
        Rails.logger.info "Successfully set payment method #{payment_method_id} as default for customer #{customer_id}"
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Error setting default payment method: #{e.message}"
        # We'll continue with the checkout process even if we can't set the default payment method
      end
    end

    def get_promotion_code(code)
      nil if code.blank? || code == "true"

      begin
        promotion_codes = Stripe::PromotionCode.list({
          code: code,
          active: true,
          limit: 1
        })

        if promotion_codes.data.empty?
          Rails.logger.info "Invalid coupon provided: #{code}. Proceeding without coupon."
        else
          promotion_codes.data.first
        end
      rescue Stripe::StripeError => e
        Rails.logger.error "Error applying coupon: #{e.message}"
        Rails.logger.info "Proceeding without coupon."
      end
    end

    def create_purchase_records(setup_intent_or_payment_intent, options = {})
      # Determine if we're handling a trial subscription or regular purchase
      is_trial_subscription = setup_intent_or_payment_intent.is_a?(Stripe::SetupIntent)
      payment_intent = is_trial_subscription ? nil : setup_intent_or_payment_intent
      setup_intent = is_trial_subscription ? setup_intent_or_payment_intent : nil
      subscription = options[:subscription]

      # Retrieve the payment method details
      if is_trial_subscription
        # For trial subscriptions, the payment method might be on the subscription instead of the setup intent
        if setup_intent.payment_method.present?
          payment_method = Stripe::PaymentMethod.retrieve(setup_intent.payment_method)
          processor_payment_method_id = setup_intent.payment_method
        elsif subscription && subscription.default_payment_method.present?
          # If the setup intent doesn't have a payment method, try to get it from the subscription
          payment_method = Stripe::PaymentMethod.retrieve(subscription.default_payment_method)
          processor_payment_method_id = subscription.default_payment_method
        else
          # If we still can't find a payment method, log an error and return
          Rails.logger.error "Could not find payment method for trial subscription"
          return
        end
        processor_customer_id = setup_intent.customer
      else
        processor_payment_method_id = payment_intent.payment_method
        processor_customer_id = payment_intent.customer
        # Retrieve the payment method to get card details
        payment_method = Stripe::PaymentMethod.retrieve(processor_payment_method_id)
      end

      # Get payment method details based on type
      payment_details = case payment_method.type
      when "card"
        payment_method.card
      when "amazon_pay"
        # For Amazon Pay, we'll use some default values since we don't have card details
        OpenStruct.new(
          brand: "amazon_pay",
          last4: "amazon",
          exp_month: nil,
          exp_year: nil
        )
      when "cashapp"
        # For Cash App Pay, we'll use some default values since we don't have card details
        OpenStruct.new(
          brand: "cash_app",  # Using a valid brand value
          last4: payment_method.cashapp.cashtag.to_s.gsub("$", ""),  # Store the cashtag without the $ symbol
          exp_month: nil,
          exp_year: nil
        )
      else
        Rails.logger.error "Unsupported payment method type: #{payment_method.type}"
        return
      end

      # Create payment method record
      # Check if a payment method with the same last4 and brand already exists
      existing_payment_method = current_account.payment_methods.find_by(
        last4: payment_details.last4,
        brand: payment_details.brand
      )

      if existing_payment_method
        # If expiration details are different, update the existing payment method
        if payment_details.exp_month && payment_details.exp_year && (
           existing_payment_method.expiration_month != payment_details.exp_month ||
           existing_payment_method.expiration_year != payment_details.exp_year
        )

          # Update the existing payment method with new details
          existing_payment_method.update!(
            processor_payment_method_id: processor_payment_method_id,
            processor_customer_id: processor_customer_id,
            expiration_month: payment_details.exp_month,
            expiration_year: payment_details.exp_year,
            default: true
          )

          # Set all other payment methods to default: false
          current_account.payment_methods.where.not(id: existing_payment_method.id).update_all(default: false)

          payment_method_record = existing_payment_method
        else
          # All details are exactly the same, do nothing
          payment_method_record = existing_payment_method
        end
      else
        # No matching payment method exists, create a new one
        payment_method_record = current_account.payment_methods.create!(
          processor_payment_method_id: processor_payment_method_id,
          processor_customer_id: processor_customer_id,
          brand: payment_details.brand,
          last4: payment_details.last4,
          expiration_month: payment_details.exp_month,
          expiration_year: payment_details.exp_year,
          default: true
        )

        # Set all other payment methods to default: false
        current_account.payment_methods.where.not(id: payment_method_record.id).update_all(default: false)
      end

      # Create purchase record
      purchase = current_account.purchases.create!(
        product_id: @product.id,
        price_id: @price.id,
        payment_method_id: payment_method_record.id,
        processor_customer_id: processor_customer_id
      )

      # Create subscription record (if it's a subscription)
      if subscription.present?
        # Map Stripe subscription status to our subscription status
        subscription_status = case subscription.status
        when "active", "trialing"
          subscription.status
        when "incomplete", "incomplete_expired", "past_due", "unpaid"
          "past_due"
        when "canceled"
          "cancelled"
        else
          "active"  # Default to active for any other status
        end

        current_account.subscriptions.create!(
          product_id: @product.id,
          purchase_id: purchase.id,
          price_id: @price.id,
          payment_method_id: payment_method_record.id,
          processor_customer_id: processor_customer_id,
          processor_subscription_id: subscription.id,
          status: subscription_status,
          current_period_end: Time.at(subscription.items.first.current_period_end)
        )

        # Update the account's subscription status
        current_account.update!(subscription_status: is_trial_subscription ? "trialing_subscription" : "paying_subscription")
      end

      # If today's payment is different from the purchase price (e.g. a discount was applied),
      # pass this along to the mailer sent to admin
      admin_mailer_options = {}
      if setup_intent_or_payment_intent.respond_to?(:amount)
        today_payment = setup_intent_or_payment_intent&.amount
        if today_payment.present? && today_payment != purchase.price.amount
          admin_mailer_options[:today_payment] = today_payment
        end
      end

      # Send an email to the admin when a new purchase is made
      CommerceMailer.admin_new_purchase(purchase, admin_mailer_options).deliver_later

      # Create payment record for regular purchases or non-trial subscriptions
      if !is_trial_subscription || (subscription && !subscription.trial_end)
        # Map Stripe payment intent status to our payment status
        payment_status = case payment_intent.status
        when "succeeded"
          "succeeded"
        when "requires_confirmation", "processing"
          "pending"
        else
          "failed"
        end
        payment_params = {
          purchase_id: purchase.id,
          payment_method_id: payment_method_record.id,
          processor_payment_id: payment_intent.id,
          processor_customer_id: processor_customer_id,
          amount: payment_intent.amount,
          currency: payment_intent.currency,
          status: payment_status
        }

        if payment_intent.metadata["subscription_id"].present?
          payment_params[:processor_invoice_id] = payment_intent.metadata["subscription_id"]
        end

        if subscription.present?
          # Find our internal subscription record to get its ID
          internal_subscription = current_account.subscriptions.find_by(processor_subscription_id: subscription.id)
          payment_params[:subscription_id] = internal_subscription.id if internal_subscription
        end

        payment = current_account.payments.create!(payment_params)
      end
    end
  end
end
