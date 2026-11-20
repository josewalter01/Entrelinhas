require "test_helper"

class MuralTest < ActionDispatch::IntegrationTest
  def fields
    { author_name: "Ana", published_on: "2026-03-07", body: "Observação\n\nLinha dois\nLinha três" }
  end

  def sample(name, type)
    Rack::Test::UploadedFile.new(Rails.root.join("db/exemplos", name), type)
  end

  def uploaded(bytes, name, type)
    Rack::Test::UploadedFile.new(StringIO.new(bytes.b), type, original_filename: name)
  end

  def publish(extra = {})
    post posts_path, params: { post: fields.merge(extra) }
  end

  test "mural vazio convida à primeira publicação e formulário usa HTTP multipart" do
    get root_path
    assert_response :success
    assert_select 'a[href=?]', new_post_path, text: "Criar primeira publicação"
    get new_post_path
    assert_select 'form[action=?][method=post][enctype="multipart/form-data"]', posts_path
    assert_select 'input[type=date][value=?]', Date.current.iso8601
    assert_select 'input[type=file]:not([required])'
    assert_select 'textarea[required]'
    assert_select 'a[href=?]', root_path, text: "Cancelar"
    assert_select "script", count: 0
  end

  test "criação redireciona, mostra confirmação e exibe conteúdo escapado" do
    assert_difference("Post.count", 1) { publish(body: "<b>Teste</b>\n\nLinha 2\nLinha 3") }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", text: "Publicação adicionada ao mural."
    assert_select "article b", count: 0
    assert_select "article .lead", text: "<b>Teste</b>"
    assert_equal "Linha 2\nLinha 3", css_select("article .prose").first.text
    assert_select "time[datetime='2026-03-07']", text: "07 de mar de 2026"
    assert_equal "Ana", Post.last.reload.author_name
    assert_select "script", count: 0
  end

  test "erro preserva valores e identifica o campo" do
    assert_no_difference("Post.count") { publish(author_name: " ") }
    assert_response :unprocessable_content
    assert_select '[role=alert] a[href="#post_author_name"]', text: "Nome é obrigatório."
    assert_select 'textarea', text: fields[:body]
    assert_select 'input[type=date][value=?]', fields[:published_on]
  end

  test "tema persiste na sessão, preserva filtro e alterna nas duas direções" do
    patch theme_path, params: { theme: "escuro", tipo: "documentos" }
    assert_redirected_to root_path(tipo: "documentos")
    follow_redirect!
    assert_select 'html[data-theme=escuro]'
    get new_post_path
    assert_select 'html[data-theme=escuro]'
    guest = open_session
    guest.get root_path
    guest.assert_select 'html[data-theme=claro]'
    patch theme_path, params: { theme: "claro" }
    follow_redirect!
    assert_select 'html[data-theme=claro]'
  end

  test "JPEG e PDF ficam persistidos, são filtrados e devolvem os bytes originais" do
    [["vista-de-sao-paulo-do-potengi.jpg", "image/jpeg", "imagens", "inline"],
     ["roteiro-de-campo.pdf", "application/pdf", "documentos", "attachment"]].each do |name, mime, filter, disposition|
      publish(attachment: sample(name, mime))
      assert_response :redirect
      assert_equal mime, Post.last.reload.attachment.content_type
      get root_path(tipo: filter)
      assert_select "article", count: 1
      element = css_select(mime == "image/jpeg" ? "article figure img" : "article a.file-link").first
      assert element
      get element[mime == "image/jpeg" ? "src" : "href"]
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_equal mime, response.media_type
      assert_match(/\A#{disposition}/, response.headers["Content-Disposition"])
      assert_equal File.binread(Rails.root.join("db/exemplos", name)), response.body.b
    end
  end

  test "aceita PNG e WebP com assinatura válida" do
    %w[png webp].each do |ext|
      f = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/pixel.#{ext}"), "image/#{ext}")
      assert_difference("Post.count") { publish(attachment: f) }
      assert_equal "image/#{ext}", Post.last.reload.attachment.content_type
    end
  end

  test "rejeita arquivo disfarçado, vazio, extensão incompatível, formato ativo e referência textual" do
    failures = [
      uploaded("texto comum", "foto.jpg", "image/jpeg"),
      uploaded("", "foto.png", "image/png"),
      uploaded(File.binread(Rails.root.join("db/exemplos/roteiro-de-campo.pdf")), "foto.jpg", "image/jpeg"),
      uploaded("<svg xmlns='http://www.w3.org/2000/svg'/>", "mapa.svg", "image/svg+xml"),
      "referencia-invalida"
    ]
    failures.each do |file|
      assert_no_difference(["Post.count", "ActiveStorage::Blob.count"]) { publish(attachment: file) }
      assert_response :unprocessable_content
      assert_select '[role=alert] a[href="#post_attachment"]'
    end
  end

  test "rejeita arquivo acima do limite sem persistir blob nem postagem" do
    file = uploaded("%PDF-" + "x" * Post::MAX_FILE_SIZE, "grande.pdf", "application/pdf")
    assert_no_difference(["Post.count", "ActiveStorage::Blob.count"]) { publish(attachment: file) }
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /até 8 MiB/
  end

  test "ordem cronológica no HTML e filtros vazios" do
    publish(author_name: "Recente", published_on: "2026-10-19")
    publish(author_name: "Antiga", published_on: "2024-01-01")
    get root_path
    assert_equal %w[Recente Antiga], css_select("article h3").map(&:text)
    get root_path(tipo: "imagens")
    assert_select "article", count: 0
    assert_select "h3", text: "Nenhuma publicação neste filtro"
  end

  test "campos administrativos não podem ser alterados no formulário público" do
    publish(id: -712, created_at: "2000-01-01", updated_at: "2000-01-01")
    assert_redirected_to root_path
    saved = Post.sole
    assert_operator saved.id, :>, 0
    assert_operator saved.created_at.year, :>, 2000
    assert_operator saved.updated_at.year, :>, 2000
  end

  test "paginação limita os cards e preserva a sequência" do
    21.times { |i| Post.create!(fields.merge(author_name: "Autor #{i}")) }
    get root_path
    assert_select "article", count: 20
    assert_select 'a[rel=next]'
    get css_select("a[rel=next]").first["href"]
    assert_select "article", count: 1
    assert_select "article h3", text: "Autor 0"
    assert_select "a[rel=prev]"
    assert_select "a[rel=next]", count: 0
    patch theme_path, params: { theme: "escuro", pagina: 2 }
    assert_redirected_to root_path(pagina: 2)
    get root_path(pagina: "inválida")
    assert_select "article", count: 20
  end

  test "troca de tema descarta página e filtro inválidos como o mural" do
    patch theme_path, params: { theme: "escuro", pagina: "100000000", tipo: "outros" }
    assert_redirected_to root_path
    follow_redirect!
    assert_select 'html[data-theme=escuro]'
    assert_select "h2#feed-title", text: "Mural de publicações"
  end

  test "texto com caractere nulo recebe mensagem de validação" do
    assert_no_difference("Post.count") { publish(body: "Antes\0depois") }
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /caractere nulo/
  end

  test "o mural reflete a edição e a remoção de uma postagem persistida" do
    publish
    saved = Post.sole
    saved.update!(body: "Relato revisado")
    get root_path
    assert_select "article .prose", text: "Relato revisado"
    saved.destroy!
    get root_path
    assert_select "article", count: 0
    assert_select "h3", text: "O mural começa com você"
  end
end
