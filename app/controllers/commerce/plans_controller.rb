module Commerce
  class PlansController < ApplicationController
    allow_unauthenticated_access(only: [ :index ])

    layout "checkout"

    def index
      # This is the public page for non-authenticated users to view and choose a plan.

      if authenticated?
        @account = current_account
        if @account.present?
          if current_user.account_admin?(@account)

            if @account.subscriptions.active_or_trialing.count == 1
              # if account has only 1 subscription, redirect to this subscription's edit plan page
              redirect_to edit_plan_path(account_slug: @account.slug, id: @account.subscriptions.first.id)
            elsif @account.subscriptions.count > 1
              # if account has multiple subscriptions, redirect to billing overview page
              redirect_to billing_overview_path(account_slug: @account.slug)
            else
              # If account has no subscription yet,
              # stay on this page so that they can choose a plan and create their first subscription
            end

          else # non-account-admins can't see plans page. Redirect to root path.
            redirect_to root_path, alert: t("commerce.plans.not_authorized_alert", default: "You are not authorized to access this page.")
          end
        end
      end

      @plans = ::Commerce::Plan.active
    end
  end
end
