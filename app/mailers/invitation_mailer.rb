class InvitationMailer < ApplicationMailer
  before_action :set_colors_and_styles

  def invitation_email(invitation)
    @account = invitation.account
    @invitation = invitation
    mail(to: @invitation.email,
         subject: t("teams.invitation_mailer.invitation_subject", account: @invitation.account.name, default: "Invitation to join %{account}"))
  end

  def invitation_accepted_email(invitation, invitee_user)
    @invitation = invitation
    @invited_user = invitee_user
    recipient_email = @invitation.user.present? ? @invitation.user.email_address : @invitation.account.owner.email_address
    @manage_member_url = edit_account_user_url(@invitation.account.slug, @invited_user.id)
    mail(to: recipient_email,
         subject: t("teams.invitation_mailer.invitation_accepted_subject", name: invitee_user.name, default: "%{name} accepted your invitation"))
  end

  private

  def set_colors_and_styles
    @primary_color = fetch_primary_color
    @button_style = button_style(@primary_color, "white")
  end

  def fetch_primary_color
    css_path = Rails.root.join("app", "assets", "tailwind", "colors.css")
    default_fallback_color = "#06acff"
    if File.exist?(css_path)
      css_content = File.read(css_path)
      # Extract the primary color using regex
      match = css_content.match(/--color-primary:\s*(#[0-9a-fA-F]{6})/)
      match ? match[1] : default_fallback_color # Default fallback if not found
    else
      default_fallback_color # Default fallback if file not found
    end
  end

  def button_style(background_color, text_color)
    "background-color: #{background_color}; color: #{text_color}; padding: 10px 20px; border-radius: 5px; text-decoration: none;"
  end
end
