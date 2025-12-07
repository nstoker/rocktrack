module Commerce
  class PlanBenefit < ApplicationRecord
    self.table_name = "commerce_plan_benefits"
    belongs_to :plan
    belongs_to :benefit
    positioned on: :plan
  end
end
