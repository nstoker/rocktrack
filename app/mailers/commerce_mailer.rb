class CommerceMailer < ApplicationMailer
  helper CommerceHelper

  before_action :set_colors_and_styles
  before_action :set_admin_email_address

  def dunning_email(payment)
    @payment = payment
    @subscription = payment.subscription
    @product = @subscription.product
    @account = payment.account
    @user = @account.owner

    mail(
      to: @user.email_address,
      subject: t("commerce.mailers.dunning_email.subject", product: @product.name, default: "Action Required: Your payment for #{@product.name} was declined")
    )
  end

  def admin_new_purchase(purchase, options = {})
    # This is a notification to the app admin(s) that a purchase has been made.

    @purchase = purchase
    @today_payment = options[:today_payment] # This would be present if today's payment is different (i.e. discounted) from the normal price of the purchased product
    @product = purchase&.product
    @subscription = purchase&.subscriptions&.first
    @account = @purchase.account

    if @admin_email_address.present?
      mail(
        to: @admin_email_address,
        reply_to: @account.owner.email_address,
        subject: t("commerce.mailers.admin_new_purchase.subject", product: @product.name, account: @account.name, email: @account.owner.email_address, default: "[New Purchase of #{@product.name}] #{@account.name} - #{@account.owner.email_address}")
      )
    else
      Rails.logger.error "No admin user found to send new purchase notification"
    end
  end

  def admin_subscription_cancellation_initiated(subscription)
    # This is a notification to the app admin(s) that a subscription cancellation has been initiated.

    @subscription = subscription
    @account = subscription.account

    if @admin_email_address.present?
      mail(
        to: @admin_email_address,
        reply_to: @account.owner.email_address,
        subject: t("commerce.mailers.admin_subscription_cancellation_initiated.subject", account: @account.name, email: @account.owner.email_address, default: "[Cancellation] #{@account.name} - #{@account.owner.email_address}")
      )
    else
      Rails.logger.error "No admin user found to send subscription cancellation notification"
    end
  end

  def admin_subscription_plan_changed(subscription, options = {})
    # This is a notification to the app admin(s) that a subscription's plan has been changed

    @subscription = subscription
    @previous_product_name = options[:previous_product_name]
    @new_product_name = options[:new_product_name]
    @previous_price_name = options[:previous_price_name]
    @new_price_name = options[:new_price_name]
    @account = subscription.account

    if @admin_email_address.present?
      mail(
        to: @admin_email_address,
        reply_to: @account.owner.email_address,
        subject: t("commerce.mailers.admin_subscription_plan_changed.subject", account: @account.name, email: @account.owner.email_address, default: "[Subscription Plan Changed] #{@account.name} - #{@account.owner.email_address}")
      )
    else
      Rails.logger.error "No admin user found to send subscription plan change notification"
    end
  end

  private

  def set_admin_email_address
    admin_user = User.where(admin: true).first
    if admin_user
      @admin_email_address = admin_user.email_address
    end
  end

  def set_colors_and_styles
    @primary_color = fetch_primary_color
    @button_style = button_style(@primary_color, "white")
  end

  def fetch_primary_color
    css_path = Rails.root.join("app", "assets", "tailwind", "colors.css")
    default_fallback_color = "#06acff"
    if File.exist?(css_path)
      css_content = File.read(css_path)
      # Extract the primary color using regex
      match = css_content.match(/--color-primary:\s*(#[0-9a-fA-F]{6})/)
      match ? match[1] : default_fallback_color # Default fallback if not found
    else
      default_fallback_color # Default fallback if file not found
    end
  end

  def button_style(background_color, text_color)
    "background-color: #{background_color}; color: #{text_color}; padding: 10px 20px; border-radius: 5px; text-decoration: none;"
  end
end
