module Admin
  class AdminController < ApplicationController
    before_action :authorize_admin_user
    include Pagy::Backend # Warning throws an `uninitialized constant Pagy::Backend`
    layout "admin"
  end
end
