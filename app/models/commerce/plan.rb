module Commerce
  class Plan < ApplicationRecord
    positioned
    self.table_name = "commerce_plans"

    belongs_to :price_a, class_name: "Commerce::Price", optional: true
    belongs_to :price_b, class_name: "Commerce::Price", optional: true

    has_many :plan_benefits, class_name: "Commerce::PlanBenefit"
    has_many :benefits, through: :plan_benefits

    validates :name, presence: true, uniqueness: true
    validates :display_name, presence: true

    scope :active, -> { where(active: true) }
  end
end
