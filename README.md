# Entrelinhas

Blog acadêmico inspirado no IFRN. A página inicial reúne relatos em ordem cronológica e permite filtrar os que têm imagem ou PDF. O formulário, o upload e a escolha de tema funcionam com HTML renderizado pelo Rails e requisições HTTP tradicionais.

## Executar

Use Ruby 3.4.x e Bundler. O projeto foi validado com Ruby 3.4.6 e Rails 8.1.4.1. Desenvolvimento e testes usam SQLite local. Produção usa PostgreSQL pela variável DATABASE_URL. Na pasta que contém o Gemfile:

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

Abra [o mural local](http://localhost:3000). Na primeira preparação, o Rails cria o esquema e o mural começa vazio. Se o Bundler precisar compilar extensões na sua plataforma, instale as ferramentas de compilação do Ruby e os cabeçalhos de SQLite do sistema.

No workspace original do Codex, `bash outputs/iniciar.sh` também inicia a aplicação usando o Ruby já preparado.

## Como o código se organiza

| Responsabilidade | Onde encontrar |
| --- | --- |
| Atributos, validações, consulta do feed e regras dos anexos | `app/models/post.rb` |
| Mural, filtros, formulário, criação e preferência de tema | `app/controllers/application_controller.rb` |
| HTML compartilhado, idioma, estilos e cabeçalho | `app/views/layouts/application.html.erb` |
| Feed, card reutilizado e formulário | `app/views/posts/` |
| Paleta, tipografia, foco e layout responsivo | `public/assets/caderno.css` |
| Banco e serviço de arquivos de cada ambiente | `config/database.yml` e `config/storage.yml` |
| Evolução do esquema e inicialização do banco | `db/migrate/` e `db/seeds.rb` |

`GET /` e `GET /publicacoes` listam as postagens. `GET /publicacoes/nova` abre o formulário. `POST /publicacoes` valida e salva a publicação. Em caso de sucesso, um redirecionamento HTTP 303 leva ao mural e evita repetir o envio ao atualizar a página. Em caso de erro, o servidor devolve o formulário com status 422, valores preenchidos e mensagens vinculadas aos campos. O navegador exige selecionar o arquivo novamente.

A data informada é uma coluna SQL `date`. A data inicial segue o fuso `America/Fortaleza`. O feed usa `published_on`, `created_at` e `id`, em ordem decrescente, para desempatar publicações. O texto admite 30.000 caracteres e o nome admite 100. O ERB escapa ambos. CSS preserva as quebras de linha. Um parágrafo inicial curto separado por linha em branco recebe destaque tipográfico.

O botão de tema no mural envia um formulário para `PATCH /tema`. O servidor guarda a opção na sessão, renderiza `data-theme` no elemento `html` e mantém o filtro ativo. O formulário de publicação herda o tema escolhido. A primeira visita usa o tema claro. CSS, fontes, ícones e fotografias são servidos localmente.

## Arquivos, segurança e armazenamento

Cada publicação aceita um anexo de até 8 MiB. O servidor verifica o tamanho, identifica o tipo pelos bytes com Marcel e compara o resultado com a extensão. JPEG, PNG e WebP aparecem como imagens. O PDF é servido como download. Os anexos usam chaves internas do Active Storage e ficam fora de `public/`. As duas rotas públicas de leitura usam assinaturas do Rails. A única entrada pública de arquivos é o formulário da postagem.

A aplicação usa proteção CSRF e política de conteúdo com `script-src 'none'` e `object-src 'none'`. O banco relacional guarda as publicações e os metadados dos anexos. O Active Storage guarda os arquivos em disco.

| Ambiente | Banco | Anexos |
| --- | --- | --- |
| Desenvolvimento | `storage/development.sqlite3` | `storage/files/` |
| Teste | `tmp/test.sqlite3` | `tmp/test-files/` |
| Produção | PostgreSQL via `DATABASE_URL` | `storage/files/` |

Em produção, use armazenamento persistente para `storage/` e defina `SECRET_KEY_BASE` no ambiente. Em produção, faça backup do PostgreSQL e dos arquivos do Active Storage em conjunto, com as escritas suspensas. O SQLite admite um escritor por vez. O tamanho da página do feed é 20. O controller busca um registro adicional para detectar a próxima página e carrega os anexos em lote.

## Alcance do protótipo

O mural é público. O nome do autor é autodeclarado. As páginas usam offset. Inserções entre cliques podem deslocar um item de página, e offsets profundos custam mais. A hospedagem requer disco persistente para os anexos ou um serviço alternativo de Active Storage.

A identificação de tipo verifica assinaturas de arquivo. Ela não equivale a uma inspeção antivírus ou à decodificação integral do documento. O navegador recebe imagens no tamanho original e o CSS limita sua exibição. O texto alternativo usa o nome do autor e o nome do arquivo. Nomes de arquivo descritivos favorecem a leitura assistiva.

A inspeção visual usou Chromium em Linux. A entrega não inclui auditoria com leitor de tela ou homologação em navegadores móveis nativos.

## Identidade e créditos

A paleta parte do verde `#2f9e41` e do vermelho `#cd191e` do manual institucional. Os botões usam verde mais escuro no tema claro e verde claro no tema escuro para manter a leitura. Os logotipos são do portal do IFRN. O Entrelinhas é um protótipo acadêmico independente. [Manual de Aplicação da Marca, página 14](https://portal.ifrn.edu.br/documents/3770/Manual_da_marca_2.pdf).

A foto da fachada do Campus São Paulo do Potengi, de Alberto Medeiros, vem do [acervo do IFRN](https://portal.ifrn.edu.br/campus/reitoria/noticias/campus-sao-paulo-do-potengi-inicia-inscricoes-para-os-primeiros-cursos/). A vista aérea da cidade em `public/assets/vista-de-sao-paulo-do-potengi.jpg` vem da [página do campus](https://portal.ifrn.edu.br/campus/sao-paulo-do-potengi/).

As fontes locais são DM Sans e Newsreader. Os ícones são do Lucide. As licenças acompanham os arquivos em `public/assets/`.

## Railway

No serviço Rails em produção, referencie a variável privada do serviço de banco em DATABASE_URL. Configure bin/rails db:migrate uma única vez no deploy. O arquivo db/production_schema.rb pertence ao PostgreSQL; db/schema.rb pertence ao SQLite. Faça backup dos dados existentes antes de implantar esta versão.

## Licença

O código do Entrelinhas é distribuído sob a GNU Affero General Public License, versão 3. [Leia a licença completa](LICENSE).

Os créditos das fotografias, marcas, fontes e ícones estão na seção [Identidade e créditos](#identidade-e-créditos).
