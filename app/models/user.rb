class User < ApplicationRecord
  attr_accessor :invite

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  has_many :invitations, dependent: :nullify

  after_create :create_account

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }



  has_one_attached :avatar

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name
    if first_name? && last_name?
      "#{first_name} #{last_name}"
    elsif first_name?
      first_name
    elsif last_name?
      last_name
    else
      email_address
    end
  end


  def initials
    if first_name?
      first_initial = first_name[0]
      last_initial = last_name[0] if last_name?
      "\#{first_initial}\#{last_initial}"
    else
      email_address[0].to_s
    end
  end


  def account_user(account)
    account.account_users.find_by(user: self)
  end

  def account_user?(account)
    account_user(account).present?
  end

  def account_role(account)
    account_user(account)&.role
  end

  def account_owner?(account)
    account.owner_id == self.id
  end

  def account_admin?(account)
    account_role(account) == "admin"
  end

  def account_member?(account)
    account_role(account) == "member"
  end


  private


  def create_account
    return if self.invite

    account_name = self.email_address.split("@").first
    account = Account.create(name: account_name, owner_id: self.id)
    account_user = AccountUser.create(account: account, user: self, role: "admin")
  end


end
