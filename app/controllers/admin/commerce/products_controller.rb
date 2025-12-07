module Admin
  module Commerce
    class ProductsController < AdminController
      include Pagy::Backend

      before_action :set_product, only: [ :edit, :update, :destroy, :remove_image ]

      def commerce_root
        redirect_to admin_products_path
      end

      def index
        @products = ::Commerce::Product.all

        @pagy, @products = pagy(@products, items: 20)
      end

      def new
        @product = ::Commerce::Product.new
      end

      def edit
        @prices = @product.prices
      end

      def create
        @product = ::Commerce::Product.new(product_params)

        if @product.save
          redirect_to admin_edit_product_path(@product.slug), notice: t("admin.products.flash.created", default: "Product was successfully created.")
        else
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          redirect_to admin_edit_product_path(@product.slug, active_panel: "details"), notice: t("admin.products.flash.updated", default: "Product was successfully updated.")
        else
          @prices = @product.prices
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @product.destroy
        redirect_to admin_products_path, notice: t("admin.products.flash.deleted", default: "Product was successfully deleted.")
      end

      def remove_image
        @product.image.purge
        redirect_to admin_edit_product_path(@product.slug), notice: t("admin.products.flash.image_removed", default: "Image removed successfully.")
      end

      private

      def set_product
        @product = ::Commerce::Product.find_by(slug: params[:slug])
      end

      def product_params
        params.require(:commerce_product).permit(:name,
                                                 :description,
                                                 :image,
                                                 :slug,
                                                 :active,
                                                 :processor_product_id
                                                )
      end
    end
  end
end
