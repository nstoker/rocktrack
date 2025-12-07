module Commerce
  class Payment < ApplicationRecord
    self.table_name = "commerce_payments"
    belongs_to :account
    belongs_to :payment_method, optional: true
    belongs_to :purchase, optional: true
    belongs_to :subscription, optional: true
    belongs_to :resolved_by_payment, class_name: "Commerce::Payment", optional: true

    enum :status, {
      pending: 0,
      succeeded: 1,
      failed: 2,
      resolved: 3
    }

    before_create :generate_resolve_token, if: :failed?

    private

    def generate_resolve_token
      self.resolve_token = SecureRandom.urlsafe_base64(32)
    end
  end
end
