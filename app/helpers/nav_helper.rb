module NavHelper
  def active_nav_link?(path, options = {})
    # options can be an array of paths or a hash.
    # if it's an array, it will consider this the sub_links array.

    # Check if current page matches the main path
    return true if current_page?(path)

    # Determine if we should include nested paths
    include_nested = options.key?(:include_nested) ? options[:include_nested] : true

    # Check if current path starts with the given path (for nested routes)
    # Skip this check for root_path to avoid matching everything
    return true if include_nested && path != root_path && request.path.start_with?(path)

    # Extract sub_links from options
    sub_links = if options[:sub_links].present?
                  options[:sub_links]
    elsif options.is_a?(Array)
                  options
    end

    # Check if any sub-links match the current page
    if sub_links.present?
      sub_links.any? do |link|
        link_url = link.is_a?(Hash) ? link[:url] : link
        next if link.is_a?(Hash) && link[:sub_link_header] == true
        next if link_url == "#" # Skip placeholder links
        current_page?(link_url)
      end
    else
      false
    end
  end

  def nav_attributes(local_assigns)
    {
      # applies to the div that wraps the entire primary navigation
      container_classes: local_assigns[:container_classes],

      # applies to each of the divs that wrap the link element and their sub_links
      link_container_classes: local_assigns[:link_container_classes],
      active_link_container_classes: local_assigns[:active_link_container_classes],
      inactive_link_container_classes: local_assigns[:inactive_link_container_classes],

      # applies to each link element
      link_space_x: local_assigns[:link_space_x],
      link_padding: local_assigns[:link_padding],
      link_classes: local_assigns[:link_classes],
      inactive_link_classes: local_assigns[:inactive_link_classes],
      active_link_classes: local_assigns[:active_link_classes],

      # applies to each of the icon containers
      icon_container_classes: local_assigns[:icon_container_classes],
      inactive_icon_container_classes: local_assigns[:inactive_icon_container_classes],
      active_icon_container_classes: local_assigns[:active_icon_container_classes],

      # applies to each of the label elements
      label_classes: local_assigns[:label_classes],
      inactive_label_classes: local_assigns[:inactive_label_classes],
      active_label_classes: local_assigns[:active_label_classes],

      # applies to each of the divs that wrap each link's set of sub_links
      sub_links_container_space_y: local_assigns[:sub_links_container_space_y],
      sub_links_container_padding_y: local_assigns[:sub_links_container_padding_y],
      sub_links_container_padding_x: local_assigns[:sub_links_container_padding_x],
      sub_links_container_text_size: local_assigns[:sub_links_container_text_size],
      sub_links_container_classes: local_assigns[:sub_links_container_classes],
      sub_link_classes: local_assigns[:sub_link_classes],
      sub_link_active_classes: local_assigns[:sub_link_active_classes],
      sub_link_inactive_classes: local_assigns[:sub_link_inactive_classes]
    }
  end
end
