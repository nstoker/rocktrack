module Commerce
  class PaymentMethod < ApplicationRecord
    self.table_name = "commerce_payment_methods"
    belongs_to :account
    has_many :payments, dependent: :nullify
    has_many :purchases, dependent: :nullify
    has_many :subscriptions, dependent: :nullify

    enum :brand, {
      visa: 0,
      mastercard: 1,
      amex: 2,
      discover: 3,
      amazon_pay: 4,
      cash_app: 5
    }

    before_save :ensure_single_default

    private

    def ensure_single_default
      return unless default_changed? && default?

      # Set all other payment methods for this account to non-default
      account.payment_methods.where.not(id: id).update_all(default: false)
    end
  end
end
