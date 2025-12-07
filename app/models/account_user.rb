class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :role, { admin: 0, member: 1 }

  validates :role, presence: true
end
