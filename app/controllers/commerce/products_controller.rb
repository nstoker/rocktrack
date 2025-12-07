module Commerce
  class ProductsController < ApplicationController
    include Pagy::Backend # The usual error with `uninitialized constant Pagy::Backend`
    allow_unauthenticated_access(only: [ :index, :show ])
    before_action :set_product, only: [ :show ]

    def index
      @products = Commerce::Product.active

      @pagy, @products = pagy(@products, items: 12)
    end

    def show
      @prices = @product.prices
    end

    private

    def set_product
      @product = Commerce::Product.find_by(slug: params[:slug])
    end
  end
end
