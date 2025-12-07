module Commerce
  class Purchase < ApplicationRecord
    self.table_name = "commerce_purchases"

    belongs_to :account
    belongs_to :product
    belongs_to :payment_method, optional: true
    belongs_to :price, optional: true
    has_many :payments
    has_many :subscriptions
    has_one :first_payment, class_name: "Payment", foreign_key: :purchase_id
  end
end
