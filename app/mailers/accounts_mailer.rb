class AccountsMailer < ApplicationMailer
  before_action :set_admin_email_address

  def admin_account_created(account)
    # This is a notification to the app admin(s) that an account has been created.

    @account = account

    if @admin_email_address.present?
      mail(
        to: @admin_email_address,
        reply_to: @account.owner.email_address,
        subject: t("teams.accounts_mailer.account_created_subject", account: @account.name, owner_email: @account.owner.email_address, default: "[New Account Created] %{account} - %{owner_email}")
      )
    else
      Rails.logger.error "No admin user found to send account creation notification"
    end
  end

  private

  def set_admin_email_address
    admin_user = User.where(admin: true).first
    if admin_user
      @admin_email_address = admin_user.email_address
    end
  end
end
