class PostsController < ApplicationController
  PAGE_SIZE = 20

  def index
    @filter = feed_filter
    @page = feed_page || 1
    offset = (@page - 1) * PAGE_SIZE
    rows = Post.for_feed(@filter).limit(PAGE_SIZE + 1).offset(offset).to_a
    @has_next = rows.size > PAGE_SIZE
    @posts = rows.first(PAGE_SIZE)
  end

  def new
    @post = Post.new(published_on: Date.current)
  end

  def create
    fields = params.expect(post: [:author_name, :published_on, :body, :attachment])
    @post = Post.new(fields.except(:attachment))
    @post.receive_upload(fields[:attachment])
    if @post.save
      redirect_to root_path, notice: "Publicação adicionada ao mural.", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end
end
