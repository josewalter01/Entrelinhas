class ConstrainPostContent < ActiveRecord::Migration[8.1]
  def change
    # SQLite does not enforce the declared width of a varchar column.
    whitespace = "char(9, 10, 11, 12, 13, 32)"
    add_check_constraint :posts,
      "length(trim(author_name, #{whitespace})) > 0 AND length(author_name) <= 100 AND instr(author_name, char(0)) = 0",
      name: "posts_author_present"
    add_check_constraint :posts,
      "length(trim(body, #{whitespace})) > 0 AND length(body) <= 30000 AND instr(body, char(0)) = 0",
      name: "posts_body_valid"
  end
end
