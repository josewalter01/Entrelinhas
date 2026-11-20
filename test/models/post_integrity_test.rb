require "test_helper"

class PostIntegrityTest < ActiveSupport::TestCase
  def fields
    { author_name: "Lara", body: "Relato", published_on: Date.current }
  end

  test "o SQLite protege o conteúdo mesmo sem as validações do model" do
    assert_equal "SQLite", Post.connection.adapter_name
    saved = Post.create!(fields)
    [{ author_name: "\t" }, { body: " \n" }, { body: "x" * 30_001 },
     { author_name: "a" * 101 }, { body: "antes\0depois" }, { published_on: nil }].each do |invalid|
      error = assert_raises(ActiveRecord::StatementInvalid) do
        saved.update_columns(invalid)
      end
      assert_kind_of SQLite3::ConstraintException, error.cause
    end
    assert_equal fields.stringify_keys, saved.reload.attributes.slice(*fields.keys.map(&:to_s))
  end

  test "um upload corrigido na mesma instância substitui o erro anterior" do
    post = Post.new(fields)
    post.receive_upload("inválido")
    assert_not post.valid?
    Tempfile.create(["foto", ".png"]) do |io|
      io.binmode
      io.write(File.binread(Rails.root.join("test/fixtures/files/pixel.png")))
      io.rewind
      post.receive_upload(ActionDispatch::Http::UploadedFile.new(tempfile: io, filename: "imagem.PNG"))
      post.save!
      assert_equal "image/png", post.reload.attachment.content_type
      assert_equal post, post.attachment.attachment.record
    end
  end

  test "valida tamanho e tipo de anexos atribuídos diretamente" do
    post = Post.new(fields)
    post.attachment.attach(io: StringIO.new("a" * (Post::MAX_FILE_SIZE + 1)), filename: "texto.txt")
    assert_not post.valid?
    assert_equal 2, post.errors[:attachment].size
  end
end
