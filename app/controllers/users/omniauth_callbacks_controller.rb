class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2, :line]

  def google_oauth2
    handle_auth("google")
  end

  def line
    handle_auth("line")
  end

  def failure
    redirect_to root_path
  end

  private

  def handle_auth(kind)
    auth = request.env["omniauth.auth"]

    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "#{kind}でログインしました"
    else
      session["devise.#{kind.downcase}_data"] = auth.except(:extra)
      redirect_to new_user_registration_url, alert: "#{kind}ログインに失敗しました"
    end
  end
end