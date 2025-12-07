module Admin
  module Commerce
    class PlanBenefitsController < AdminController
      # This manages the benefits on a plan.
      # Management of benefits themselves is handled by the BenefitsController.

      before_action :set_plan_benefit, except: [ :new, :create, :render_assign_benefit_select ]
      before_action :set_plan
      before_action :set_benefit, except: [ :new, :create, :render_assign_benefit_select ]

      def new
        @benefit = @plan.benefits.new
      end

      def render_assign_benefit_select
        # render the assign benefit selection form
      end

      def create
        # Assign existing benefit to plan OR create new benefit and assign to plan

        if params[:benefit_id].present?
          # Assign existing benefit to plan

          # Check if the benefit is already associated with the plan
          # If not, create a new plan_benefit record
          @plan_benefit = if @plan.benefits.include?(@benefit)
                            @plan.plan_benefits.find_by(benefit_id: params[:benefit_id])
          else
                            @plan.plan_benefits.create!(benefit_id: params[:benefit_id])
          end

          respond_to do |format|
            format.turbo_stream
          end
        else
          # Create new benefit
          @benefit = ::Commerce::Benefit.new(benefit_params)

          if @benefit.save
            # Create the plan_benefit record
            @plan_benefit = @plan.plan_benefits.create!(benefit: @benefit)

            respond_to do |format|
              format.turbo_stream
            end
          else
            render :new, status: :unprocessable_entity
          end
        end
      end

      def edit_benefit
        # edit a benefit when viewing a plan
      end

      def update_benefit
        # update a benefit when viewing a plan

        if @benefit.update(benefit_params)
          respond_to do |format|
            format.turbo_stream
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def reorder
        # update a plan_benefit's order on a plan
        @plan_benefit.update(position: params[:position])
      end

      def destroy
        # delete a plan_benefit (but not the benefit itself)

        if @plan_benefit.destroy
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.remove(@plan_benefit) }
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def delete_benefit
        # delete a benefit (and all plan_benefits associated with it)

        # First destroy all plan_benefits to satisfy foreign key constraints
        @benefit.plan_benefits.destroy_all

        # Then destroy the benefit
        @benefit.destroy

        respond_to do |format|
          format.turbo_stream
        end
      end

      private


      def set_plan_benefit
        @plan_benefit = ::Commerce::PlanBenefit.find(params[:id])
      end

      def set_plan
        @plan = if @plan_benefit.present?
          @plan_benefit.plan
        elsif params[:plan_id].present?
          ::Commerce::Plan.find(params[:plan_id])
        end
      end

      def set_benefit
        @benefit = if @plan_benefit.present?
          @plan_benefit.benefit
        elsif params[:benefit_id].present?
          ::Commerce::Benefit.find(params[:benefit_id])
        end
      end

      def benefit_params
        params.require(:commerce_benefit).permit(:name,
                                                 :benefit_text,
                                                 :tooltip,
                                                 :active)
      end
    end
  end
end
