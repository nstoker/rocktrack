module Admin
  module Commerce
    class BenefitsController < AdminController
      # This manages the main benefits list.
      # Manageme of benefits on plans is handled by the PlanBenefitsController.

      include Pagy::Backend

      before_action :set_benefit, only: [ :edit, :update, :destroy ]


      def index
        @benefits = ::Commerce::Benefit.all

        @pagy, @benefits = pagy(@benefits, items: 20)
      end

      def new
        @benefit = ::Commerce::Benefit.new
      end

      def create
        @benefit = ::Commerce::Benefit.new(benefit_params)

        if @benefit.save
          redirect_to admin_edit_benefit_path(@benefit), notice: t("admin.benefits.flash.created", default: "Benefit created successfully")
        else
          render :new
        end
      end

      def edit
        @plans = @benefit.plans
      end

      def update
        if @benefit.update(benefit_params)
          redirect_to admin_edit_benefit_path(@benefit), notice: t("admin.benefits.flash.updated", default: "Benefit updated successfully")
        else
          render :edit
        end
      end

      def destroy
        # First destroy all plan_benefits to satisfy foreign key constraints
        @benefit.plan_benefits.destroy_all

        if @benefit.destroy
          redirect_to admin_benefits_path, notice: t("admin.benefits.flash.deleted", default: "Benefit deleted successfully")
        else
          render :index
        end
      end

      private

      def set_benefit
        @benefit = ::Commerce::Benefit.find(params[:id])
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
