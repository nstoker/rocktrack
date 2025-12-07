module Commerce
  class Subscription < ApplicationRecord
    self.table_name = "commerce_subscriptions"

    belongs_to :account
    belongs_to :product
    belongs_to :payment_method, optional: true
    belongs_to :purchase, optional: true
    belongs_to :price
    has_many :payments

    enum :status, {
      trialing: 0,
      active: 1,
      cancelled: 2,
      past_due: 3
    }

    after_update :notify_admin_of_plan_change, if: :product_or_price_changed?

    scope :active_or_trialing, -> { where(status: [ :active, :trialing ]) }

    def cancellation_scheduled?
      [ "active", "trialing" ].include?(status) && cancellation_date.present? && cancellation_date > Time.current
    end

    def status_label_text
      if cancellation_scheduled?
        "Scheduled to cancel"
      else
        status&.humanize
      end
    end

    def plan
      Commerce::Plan.find_by(price_a_id: price_id) ||
      Commerce::Plan.find_by(price_b_id: price_id)
    end

    private

    def product_or_price_changed?
      saved_change_to_product_id? || saved_change_to_price_id?
    end

    def notify_admin_of_plan_change
      # Get the previous product and price names
      previous_product = product_id_before_last_save ? Commerce::Product.find_by(id: product_id_before_last_save) : nil
      previous_price = price_id_before_last_save ? Commerce::Price.find_by(id: price_id_before_last_save) : nil

      # Get the current product and price names
      current_product = product
      current_price = price

      # Prepare options for the mailer
      options = {
        previous_product_name: previous_product&.name,
        new_product_name: current_product&.name,
        previous_price_name: previous_price&.name,
        new_price_name: current_price&.name
      }

      # Send the notification email
      CommerceMailer.admin_subscription_plan_changed(self, options).deliver_later
    end
  end
end
