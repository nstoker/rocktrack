module Admin
  module Commerce
    class PlansController < AdminController
      include Pagy::Backend

      before_action :set_plan, only: [ :edit, :update, :destroy, :reorder ]

      def index
        @plans = ::Commerce::Plan.all

        @pagy, @plans = pagy(@plans, items: 20) # Throws a NoMethodError in Admin::Commerce::ProductsController#index
      end

      def new
        @plan = ::Commerce::Plan.new
      end

      def edit
      end

      def create
        @plan = ::Commerce::Plan.new(plan_params)

        if @plan.save
          redirect_to admin_edit_plan_path(@plan), notice: t("admin.plans.flash.created", default: "Plan was successfully created.")
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        redirect_url = if params[:commerce_plan][:active_panel].present?
          admin_edit_plan_path(@plan, active_panel: params[:commerce_plan][:active_panel])
        else
          admin_edit_plan_path(@plan)
        end

        if @plan.update(plan_params)
          redirect_to redirect_url, notice: t("admin.plans.flash.updated", default: "Plan was successfully updated.")
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @plan.destroy
        redirect_to admin_plans_path, notice: t("admin.plans.flash.deleted", default: "Plan was successfully deleted.")
      end

      def reorder
        @plan.update(position: params[:position])
      end

      private

      def plan_params
        params.require(:commerce_plan).permit(:name,
                                              :display_name,
                                              :price_a_id,
                                              :price_a_alt_amount,
                                              :price_a_append_text,
                                              :price_a_note,
                                              :price_b_id,
                                              :price_b_alt_amount,
                                              :price_b_append_text,
                                              :price_b_note,
                                              :benefits_note,
                                              :position,
                                              :active,
                                              :short_description,
                                              :button_purchase_label,
                                              :button_upgrade_label,
                                              :button_current_label,
                                              :button_downgrade_label,
                                              :button_support_text,
                                              :button_url,
                                              :highlight)
      end

      def set_plan
        @plan = ::Commerce::Plan.find(params[:id])
      end
    end
  end
end
