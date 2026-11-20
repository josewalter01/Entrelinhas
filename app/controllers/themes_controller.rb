class ThemesController < ApplicationController
  def update
    session[:theme] = params[:theme].presence_in(%w[claro escuro]) || "claro"
    redirect_to root_path(pagina: feed_page, tipo: feed_filter), status: :see_other
  end
end
