# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  def build_resource(hash = {})
    hash[:uid] = User.create_unique_string
    super
  end

  def update_resource(resource, params)
    return super if params["password"].present?

    resource.update_without_password(params.except("current_password"))
  end
  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    # 空白パラメータを除外
    account_update_params = devise_parameter_sanitizer.sanitize(:account_update)
    account_update_params.delete(:name) if account_update_params[:name].blank?
    account_update_params.delete(:email) if account_update_params[:email].blank?
    account_update_params.delete(:password) if account_update_params[:password].blank?
    account_update_params.delete(:password_confirmation) if account_update_params[:password_confirmation].blank?

    # 変更項目がない場合はエラー
    if account_update_params.except(:current_password).empty?
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
      flash[:alert] = "変更する項目を入力してください。"
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource, location: edit_user_registration_path
      return
    end

    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?

    if resource_updated
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      # メールアドレス変更時のフラッシュメッセージ
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ? :update_needs_confirmation : :updated
        set_flash_message_for_update(resource, flash_key)
      end

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :email ])
  end

  # he path used after sign up.
  def after_sign_up_path_for(resource)
    session[:just_singed_up] = true
    welcome_egg_path
  end

  # The path used after update.
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  # メールアドレス変更で確認が必要かチェック
  def update_needs_confirmation?(resource, previous)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous != resource.unconfirmed_email
  end

  # フラッシュメッセージを設定
  def set_flash_message_for_update(resource, flash_key)
    return unless is_flashing_format?

    case flash_key
    when :update_needs_confirmation
      flash[:notice] = "確認メールを #{resource.unconfirmed_email} に送信しました。メール内のリンクをクリックして変更を完了してください。"
    else
      set_flash_message :notice, :updated
    end
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
