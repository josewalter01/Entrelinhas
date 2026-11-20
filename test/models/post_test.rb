require "test_helper"

class PostTest < ActiveSupport::TestCase
  def attributes_for_post
    { author_name: " Lívia Medeiros ", published_on: Date.current, body: "Relato de campo" }
  end

  test "grava autor normalizado, data civil, texto e timestamps independentes" do
    post = Post.create!(attributes_for_post.merge(published_on: "2024-02-29")).reload
    assert_equal "Lívia Medeiros", post.author_name
    assert_equal Date.new(2024, 2, 29), post.published_on
    assert_predicate post.created_at, :present?
    assert_predicate post.updated_at, :present?
    assert_not post.attachment.attached?
  end

  test "exige nome, data válida e texto com conteúdo" do
    post = Post.new(author_name: " ", published_on: "2026-02-31", body: "\n")
    assert_not post.valid?
    assert_equal %i[author_name body published_on], post.errors.attribute_names.sort
  end

  test "aceita os limites inclusivos e rejeita o excesso" do
    post = Post.new(attributes_for_post.merge(author_name: "a" * 100, body: "b" * 30_000))
    assert_predicate post, :valid?
    post.author_name += "x"
    post.body += "x"
    assert_not post.valid?
    assert_equal %i[author_name body], post.errors.attribute_names.sort
  end

  test "ordena por data informada, criação e identificador" do
    common = attributes_for_post.merge(created_at: Time.current.change(usec: 0))
    first = Post.create!(common)
    second = Post.create!(common)
    third = Post.create!(common.merge(created_at: first.created_at + 1.minute))
    older = Post.create!(common.merge(published_on: Date.yesterday))
    assert_equal [third, second, first, older], Post.chronological.to_a
  end
end
