module SlugGenerator
  extend ActiveSupport::Concern

  class_methods do
    def slug_uniqueness_scope(record, scope_model = nil)
      if scope_model
        # Dynamic scope based on passed model
        { account_id: scope_model.id }
      else
        # Global uniqueness among all records of this class
        {}
      end
    end
  end

  def generate_random_slug(scope_model = nil)
    new_slug = SecureRandom.alphanumeric(8)
    scope = self.class.slug_uniqueness_scope(self, scope_model)

    while self.class.where(scope).where(slug: new_slug).exists?
      new_slug = SecureRandom.alphanumeric(8)
    end

    self.slug = new_slug.downcase
  end

  def generate_slug_by_name(slug_field = nil, scope_model = nil)
    if slug_field.present? && self.respond_to?(slug_field) && self.send(slug_field).present?
      base_slug = self.send(slug_field).downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-")
    elsif self.respond_to?(:name) && self.name.present?
      base_slug = self.name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-")
    elsif self.respond_to?(:title) && self.title.present?
      base_slug = self.title.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-")
    else
      return generate_random_slug(scope_model)
    end

    new_slug = base_slug
    counter = 2
    scope = self.class.slug_uniqueness_scope(self, scope_model)

    while self.class.where(scope).where(slug: new_slug).exists?
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = new_slug
  end
end
