class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def feed_filter
    params[:tipo].presence_in(Post::FEED_TYPES.keys)
  end

  def feed_page
    value = params[:pagina].to_s
    value.to_i if value.match?(/\A[1-9]\d{0,7}\z/)
  end
end
