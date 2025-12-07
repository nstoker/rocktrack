module ApplicationHelper
  include AvatarsHelper

  include FormsHelper

  include NavHelper

  def current_user
    Current.user
  end
end
