class SuapSessionsController < ApplicationController
  rescue_from SuapClient::Error do |error|
    redirect_to root_path, alert: error.message, status: :see_other
  end

  def start
    state = SecureRandom.urlsafe_base64(32)
    verifier = SecureRandom.urlsafe_base64(48)
    url = SuapClient.new.authorization_url(state, verifier)
    session[:suap_login] = { state: state, verifier: verifier, started: Time.current.to_i }
    redirect_to url, allow_other_host: true, status: :see_other
  end

  def callback
    pending = session.delete(:suap_login)
    valid = pending && pending["started"] >= 10.minutes.ago.to_i &&
      ActiveSupport::SecurityUtils.secure_compare(pending["state"], params[:state].to_s)
    unless valid && params[:code].is_a?(String) && params[:code].present? && !params.key?(:error)
      return redirect_to root_path, alert: "Login cancelado ou expirado. Entre novamente pelo mural."
    end

    profile = SuapClient.new.author_profile(params[:code], pending["verifier"])
    renew_session
    session[:suap_key] = profile[:key]
    session[:suap_name] = profile[:name]
    session[:suap_photo] = profile[:photo]
    session[:suap_until] = 8.hours.from_now.to_i
    redirect_to new_post_path
  end

  def destroy
    renew_session
    redirect_to root_path, notice: "Você saiu do Entrelinhas.", status: :see_other
  end

  private

  def renew_session
    theme = session[:theme]
    reset_session
    session[:theme] = theme
  end
end
