class InvitationsController < ApplicationController
  include Pagy::Backend
  allow_unauthenticated_access only: [ :accept_invitation, :process_invitation ]
  before_action :set_account
  before_action :authorize_user, except: [ :accept_invitation, :process_invitation ]
  before_action :set_invitation, only: [ :show, :edit, :update, :destroy ]

  layout :set_layout

  def index
    @invitations = @account.invitations

    @pagy, @invitations = pagy(@invitations, items: 12)
  end

  def new
    @invitation = @account.invitations.new
  end

  def show
  end

  def edit
  end

  def create
    @invitation = @account.invitations.new(invitation_params)
    @invitation.status = "pending"
    @invitation.token = generate_unique_token

    if @invitation.save
      InvitationMailer.invitation_email(@invitation).deliver_now
      redirect_to invitations_path(@account.slug), notice: t("teams.invitations_controller.invitation_sent", email: @invitation.email, default: "Invitation sent to %{email}!")
    else
      render :new
    end
  end

  def update
    @invitation = @account.invitations.find(params[:id])

    if @invitation.update(invitation_params)
      redirect_to invitations_path(@account.slug), notice: t("teams.invitations_controller.invitation_updated", default: "Invitation updated successfully!")
    else
      render :edit
    end
  end

  def resend
    @invitation = @account.invitations.find(params[:id])
    InvitationMailer.invitation_email(@invitation).deliver_now
    redirect_to invitations_path(@account.slug), notice: t("teams.invitations_controller.invitation_resent", default: "Invitation sent successfully!")
  end

  def accept_invitation
    @invitation = Invitation.find_by(id: params[:id], token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: t("teams.invitations_controller.invalid_invitation", default: "Invalid invitation.")
      return
    end

    if @invitation.accepted?
      redirect_to new_session_path, alert: t("teams.invitations_controller.invitation_accepted", default: "Invitation has already been accepted.")
    end
  end

  def process_invitation
    @invitation = Invitation.find_by(id: params[:id])

    if @invitation.nil?
      redirect_to root_path, alert: t("teams.invitations_controller.invalid_invitation", default: "Invalid invitation.")
      return
    end

    if @invitation.accepted?
      redirect_to new_session_path, alert: t("teams.invitations_controller.invitation_accepted", default: "Invitation has already been accepted.")
      return
    end

    # Check if user already exists
    if User.exists?(email_address: params[:email_address])
      redirect_to new_session_path, alert: t("teams.invitations_controller.user_exists", default: "A user by this email already exists.")
      return
    end

    # Create the user
    @user = User.new(email_address: params[:email_address], password: params[:password])
    @user.invite = true

    if @user.save
      # Create account_user with appropriate role
      account_user = AccountUser.create(
        account_id: @invitation.account.id,
        user_id: @user.id,
        role: @invitation.role || "member" # Default to member if not specified
      )

      # Update invitation status
      @invitation.update(status: "accepted")
      # sign in user
      start_new_session_for @user

      redirect_to root_path, notice: t("teams.invitations_controller.welcome", default: "Welcome!")

      # Send notification to invitation creator
      if @invitation.created_by_user_id.present?
        InvitationMailer.invitation_accepted_email(@invitation, @user).deliver_now
      end
    else
      render :accept_invitation
    end
  end

  def destroy
    @invitation = @account.invitations.find(params[:id])
    @invitation.destroy

    redirect_to invitations_path(@account.slug), notice: t("teams.invitations_controller.invitation_deleted", default: "Invitation deleted successfully!")
  end

  private

  def set_account
    @account = Account.find_by!(slug: params[:account_slug])
  end

  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :message, :role, :created_by_user_id)
  end

  def set_layout
    if action_name == "accept_invitation"
      "authentication"
    else
      "application"
    end
  end

  def generate_unique_token
    loop do
      token = SecureRandom.alphanumeric(20)
      break token unless Invitation.exists?(token: token)
    end
  end

  def authorize_user
    account_user = current_user.account_users.find_by(account: @account)

    unless account_user&.role == "admin"
      flash[:error] = t("teams.invitations_controller.no_permission_invitations", default: "You don't have permission to manage invitations.")
      redirect_to accounts_path
    end
  end
end
