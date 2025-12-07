class Current < ActiveSupport::CurrentAttributes
  attribute :session

  # Commented out to allow for admin impersonation of users
  # delegate :user, to: :session, allow_nil: true

  attribute :impersonated_user

  def user
    impersonated_user || session&.user
  end

  def true_user
    session&.user
  end
end
