module ApplicationHelper
  # include Pagy::Frontend # Causes a NameError (uninitialized constant Pagy::Frontend)

  include AvatarsHelper

  include FormsHelper

  include NavHelper

  def current_user
    Current.user
  end

  def current_account
    return @current_account if defined?(@current_account)

    if cookies[:current_account].present?
      account = Account.find_by(slug: cookies[:current_account])
      if account && account.users.include?(current_user)
        @current_account = account
      end
    end

    # Fallback: User's most recently created account
    @current_account = if current_user.present? && current_user.accounts.any?
                         current_user.accounts.order(created_at: :desc).first
    else
                         nil
    end
  end

end
