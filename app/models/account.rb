class Account < ApplicationRecord
  has_many :payments, class_name: "Commerce::Payment", dependent: :destroy
  has_many :payment_methods, class_name: "Commerce::PaymentMethod", dependent: :destroy
  has_many :purchases, class_name: "Commerce::Purchase", dependent: :destroy
  has_many :subscriptions, class_name: "Commerce::Subscription", dependent: :destroy
  include SlugGenerator

  belongs_to :owner, class_name: "User"
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :invitations, dependent: :destroy

  before_create :generate_slug
  after_create :send_admin_account_created_notification

  validates :name, presence: true

  enum :subscription_status, {
    no_subscription: 0,
    paying_subscription: 1,
    trialing_subscription: 2,
    subscription_past_due: 3,
    inactive_subscription: 4,
    cancelled_subscription: 5
  }

  def active_subscription?
    [ "paying_subscription", "trialing_subscription", "subscription_past_due" ].include?(subscription_status.to_s) ||
    gifted?
  end


  private

  def generate_slug
    generate_random_slug
  end

  def send_admin_account_created_notification
    AccountsMailer.admin_account_created(self).deliver_later
  end
end
