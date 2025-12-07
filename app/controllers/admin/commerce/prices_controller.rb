module Admin
  module Commerce
    class PricesController < AdminController
      include Pagy::Backend

      before_action :set_product, except: [ :index ]
      before_action :set_price, only: [ :edit, :update, :destroy ]

      def index
        @prices = ::Commerce::Price.all

        @pagy, @prices = pagy(@prices, items: 12)
      end

      def new
        @price = @product.prices.new
      end

      def create
        @price = @product.prices.build(price_params)

        if @price.save
          respond_to do |format|
            format.turbo_stream
          end
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @price.update(price_params)
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.update("commerce_price_#{@price.id}", partial: "admin/commerce/prices/price", locals: { product: @product, price: @price }) }
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @price.destroy
        respond_to do |format|
          if @product.prices.any?
            format.turbo_stream { render turbo_stream: turbo_stream.remove("commerce_price_#{@price.id}") }
          else
            format.turbo_stream { render turbo_stream: turbo_stream.update("prices", partial: "admin/commerce/prices/prices") }
          end
        end
      end

      private

      def set_product
        @product = ::Commerce::Product.find_by(slug: params[:slug])
      end

      def set_price
        @price = @product.prices.find(params[:id])
      end

      def price_params
        params.require(:commerce_price).permit(:name,
                                               :slug,
                                               :amount,
                                               :recurring,
                                               :recurring_interval,
                                               :trial_days,
                                               :processor_price_id)
      end
    end
  end
end
