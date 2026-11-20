class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  content_security_policy { |policy| policy.img_src :self, SuapClient::ORIGIN, "https://cdn.suap.ifrn.edu.br" }

  content_security_policy(only: :ballot) { |policy| policy.frame_ancestors :self }

  helper_method :signed_author
  before_action :require_author, only: %i[new create]

  PAGE_SIZE = 20

  def index
    @order = feed_order
    @filter = feed_filter
    @page = feed_page || 1
    offset = (@page - 1) * PAGE_SIZE
    rows = Post.for_feed(@filter, order: @order).limit(PAGE_SIZE + 1).offset(offset).to_a
    @has_next = rows.size > PAGE_SIZE
    @posts = rows.first(PAGE_SIZE)
    ids = @posts.map(&:id)
    @my_votes = signed_author ? Vote.where(post_id: ids, voter_key: session[:suap_key]).pluck(:post_id, :value).to_h : {}
    render "posts/index"
  end

  def new
    @post = Post.new(author_name: signed_author, published_on: Date.current)
    render "posts/new"
  end

  def create
    fields = params.expect(post: [:body, :attachment])
    @post = Post.new(body: fields[:body], published_on: Date.current, author_name: signed_author, author_key: session[:suap_key], author_photo_url: session[:suap_photo])
    @post.receive_upload(fields[:attachment])
    if @post.save
      redirect_to root_path, notice: "Publicação adicionada ao mural.", status: :see_other
    else
      render "posts/new", status: :unprocessable_content
    end
  end

  def ballot
    post = Post.find(params[:id])
    votes = Vote.where(post_id: post.id)
    current_vote = votes.where(voter_key: session[:suap_key]).pick(:value) if signed_author
    render partial: "posts/ballot", locals: { post: post, score: votes.sum(:value), current_vote: current_vote }
  end

  def vote
    return redirect_to vote_post_path(params[:id]), status: :see_other unless signed_author

    post = Post.find(params[:id])
    value = params[:value]
    return head :bad_request unless %w[-1 0 1].include?(value)

    key = { post_id: post.id, voter_key: session[:suap_key] }
    if value == "0"
      Vote.where(key).delete_all
    else
      Vote.upsert(key.merge(value: value.to_i), unique_by: [:post_id, :voter_key])
    end
    redirect_to vote_post_path(post), status: :see_other
  end

  def destroy
    return head :forbidden unless signed_author
    post = Post.find_by!(id: params[:id], author_key: session[:suap_key])
    post.destroy!
    redirect_to root_path(ordem: feed_order, tipo: feed_filter), notice: "Publicação apagada.", status: :see_other
  end

  def update_theme
    session[:theme] = params[:theme].presence_in(%w[claro escuro]) || "claro"
    redirect_to root_path(ordem: feed_order, pagina: feed_page, tipo: feed_filter), status: :see_other
  end

  private

  def signed_author
    session[:suap_name] if session[:suap_key].present? && session[:suap_until].to_i > Time.current.to_i
  end

  def require_author
    redirect_to root_path, alert: "Entre com o SUAP para publicar ou votar.", status: :see_other unless signed_author
  end

  def feed_order
    "recentes" if params[:ordem] == "recentes"
  end

  def feed_filter
    params[:tipo].presence_in(Post::FEED_TYPES.keys)
  end

  def feed_page
    value = params[:pagina].to_s
    value.to_i if value.match?(/\A[1-9]\d{0,7}\z/)
  end
end
