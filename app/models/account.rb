class Account < ApplicationRecord
  include SlugGenerator

  belongs_to :owner, class_name: "User"
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :invitations, dependent: :destroy

  before_create :generate_slug
  after_create :send_admin_account_created_notification

  validates :name, presence: true

  # PLACEHOLDER: Commerce Methods

  private

  def generate_slug
    generate_random_slug
  end

  def send_admin_account_created_notification
    AccountsMailer.admin_account_created(self).deliver_later
  end
end
