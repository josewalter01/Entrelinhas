module ApplicationHelper
  def icon(name)
    tag.svg(class: "icon", aria: { hidden: true }, focusable: false) do
      tag.use(href: "/assets/icons.svg##{name}")
    end
  end

  def initials(name)
    words = name.split
    [words.first, (words.last if words.size > 1)].compact.map { |word| word[0] }.join.upcase
  end
end
