module FormsHelper
  def form_control_classes(options = {})
    base_classes = "form-control"
    additional_classes = options[:additional_classes]

    prepend_content_present = options[:prepend_content].present?
    append_content_present = options[:append_content].present?

    rounding_classes = if prepend_content_present && append_content_present
                         "rounded-none"
    elsif prepend_content_present
                         "rounded-t-none xs:rounded-tl-none xs:rounded-bl-none xs:rounded-tr xs:rounded-br"
    elsif append_content_present
                         "rounded-b-none xs:rounded-tl xs:rounded-bl xs:rounded-tr-none xs:rounded-br-none"
    end

    "#{base_classes} #{rounding_classes} #{additional_classes}"
  end

  def data_attributes_html(hash)
    hash.map { |k, v| "data-#{k}=\"#{v}\"" }.join(" ").html_safe
  end

  def merge_data_attributes(default_data, new_data)
    default_data.merge(new_data) do |key, old_val, new_val|
      "#{old_val} #{new_val}"
    end
  end
end
