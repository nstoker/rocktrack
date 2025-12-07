module Commerce
  class Price < ApplicationRecord
    self.table_name = "commerce_prices"
    include SlugGenerator
    belongs_to :product
    has_many :subscriptions
    has_many :purchases

    has_many :plans_as_plan_a, foreign_key: "price_a_id"
    has_many :plans_as_plan_b, foreign_key: "price_b_id"

    before_create :generate_slug

    enum :recurring_interval, {
      day: 0,
      week: 1,
      month: 2,
      quarter: 3,
      year: 4
    }

    # Scope to find recurring prices
    scope :recurring, -> { where(recurring: true) }

    private

    def generate_slug
      generate_random_slug
    end
  end
end
