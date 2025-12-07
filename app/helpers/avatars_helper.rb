module AvatarsHelper
  def avatar_image_file(resource, size: 50, skip_gravatar: false)
    if resource.avatar.attached?
      resource.avatar.variant(resize_to_fill: [ size, size ])
    elsif skip_gravatar
      nil
    else
      email_address = if resource.respond_to?(:email_address)
        resource.email_address.downcase
      elsif resource.respond_to?(:email)
        resource.email.downcase
      else
        nil
      end
      hash = Digest::MD5.hexdigest(email_address)
      if hash.present?
        gravatar_size = size.to_i * 2
        "https://secure.gravatar.com/avatar/#{hash}.png?s=#{gravatar_size}&d=blank"
      else
        nil
      end
    end
  end

  def avatar_initials(resource, attribute: :name)
    text = resource.send(attribute)
    words = text.split
    if words.length >= 2
      initials = words[0][0] + words[1][0]
    else
      initials = words[0][0..1]
    end
    initials.upcase.gsub(/[^A-Z0-9]/, "")
  end

  def pixel_to_tailwind_size(pixels)
    case pixels.to_i
    when 10
      "w-4 h-4"
    when 12
      "w-5 h-5"
    when 16
      "w-6 h-6"
    when 20
      "w-8 h-8"
    when 24
      "w-8 h-8"
    when 32
      "w-10 h-10"
    when 40
      "w-10 h-10"
    when 48
      "w-12 h-12"
    when 56
      "w-14 h-14"
    when 64
      "w-16 h-16"
    when 80
      "w-20 h-20"
    when 96
      "w-24 h-24"
    else
      "w-32 h-32"
    end
  end

  def initials_text_size(size)
    pixels = size.to_i
    if pixels < 20
      "text-xs"
    elsif pixels < 33
      "text-sm"
    elsif pixels > 60
      "text-xl"
    else
      "text-base"
    end
  end
end
