module Commerce
  class Product < ApplicationRecord
    self.table_name = "commerce_products"
    include SlugGenerator

    has_many :prices
    has_many :subscriptions
    has_many :purchases

    has_one_attached :image
    has_rich_text :description

    validates :name, presence: true, uniqueness: true
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9\-_]+\z/, message: "only allows letters, numbers, hyphens, and underscores" }

    before_validation :generate_slug, on: :create

    scope :active, -> { where(active: true) }

    def to_param
      slug
    end

    def default_price
      prices.first
    end

    private

    def generate_slug
      generate_slug_by_name(:name)
    end
  end
end
