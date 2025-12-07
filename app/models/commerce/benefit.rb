module Commerce
  class Benefit < ApplicationRecord
    self.table_name = "commerce_benefits"
    has_many :plan_benefits
    has_many :plans, through: :plan_benefits
  end
end
