class Invitation < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true
  has_rich_text :message

  enum :status, { pending: 0, accepted: 1 }
  enum :role, { admin: 0, member: 1 }

  scope :pending, -> { where(status: 0) }
  scope :accepted, -> { where(status: 1) }

  validates :email, presence: true, uniqueness: { scope: :account_id }
end
