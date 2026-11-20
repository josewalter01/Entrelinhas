# Exemplos editoriais fictícios. A fotografia pertence ao acervo do portal do IFRN.
samples = [
  ["Lívia Medeiros", "2026-11-18",
   "São Paulo do Potengi visto de cima\n\nA praça e a igreja ajudam a localizar o centro nesta fotografia do acervo do IFRN. Seguindo a rua que atravessa a imagem, dá para acompanhar os quarteirões até a margem da água. Que ponto da cidade você reconhece primeiro?",
   "vista-de-sao-paulo-do-potengi.jpg"],
  ["Rafael Dantas", "2026-11-17",
   "Um roteiro para a próxima aula de campo\n\nPreparei três propostas de observação para a caminhada pelo campus. O roteiro em PDF pode ser impresso e preenchido em dupla.",
   "roteiro-de-campo.pdf"],
  ["Ana Bezerra", "2026-11-16",
   "Leituras que continuam no intervalo\n\nNa roda de leitura, cada colega trouxe um trecho de cordel para ler em voz alta. Foi ouvindo as pausas de quem lia que percebemos a mudança de ritmo entre as estrofes.",
   nil]
]

samples.each do |name, date, text, filename|
  post = Post.find_or_initialize_by(author_name: name, published_on: date, body: text)
  if filename && !post.attachment.attached?
    File.open(Rails.root.join("db/exemplos", filename), "rb") do |io|
      post.attachment.attach(io: io, filename: filename)
      post.save!
    end
  else
    post.save!
  end
end
