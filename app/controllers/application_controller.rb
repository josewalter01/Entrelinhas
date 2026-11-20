class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  PAGE_SIZE = 20

  def index
    @filter = feed_filter
    @page = feed_page || 1
    offset = (@page - 1) * PAGE_SIZE
    rows = Post.for_feed(@filter).limit(PAGE_SIZE + 1).offset(offset).to_a
    @has_next = rows.size > PAGE_SIZE
    @posts = rows.first(PAGE_SIZE)
    render "posts/index"
  end

  def new
    @post = Post.new(published_on: Date.current)
    render "posts/new"
  end

  def create
    fields = params.expect(post: [:author_name, :published_on, :body, :attachment])
    @post = Post.new(fields.except(:attachment))
    @post.receive_upload(fields[:attachment])
    if @post.save
      redirect_to root_path, notice: "Publicação adicionada ao mural.", status: :see_other
    else
      render "posts/new", status: :unprocessable_content
    end
  end

  def update_theme
    session[:theme] = params[:theme].presence_in(%w[claro escuro]) || "claro"
    redirect_to root_path(pagina: feed_page, tipo: feed_filter), status: :see_other
  end

  private

  def feed_filter
    params[:tipo].presence_in(Post::FEED_TYPES.keys)
  end

  def feed_page
    value = params[:pagina].to_s
    value.to_i if value.match?(/\A[1-9]\d{0,7}\z/)
  end
end
