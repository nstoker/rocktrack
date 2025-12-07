class User < ApplicationRecord

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

end
