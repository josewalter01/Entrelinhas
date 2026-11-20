require "net/http"
require "json"

class SuapClient
  class Error < StandardError; end

  ORIGIN = "https://suap.ifrn.edu.br"
  CALLBACK = "https://entrelinhas-production-490f5296.up.railway.app/auth/suap/callback"

  def initialize
    @client_id = ENV["SUAP_CLIENT_ID"].presence
    @secret = ENV["SUAP_CLIENT_SECRET"].presence
    @callback = ENV.fetch("SUAP_REDIRECT_URI", CALLBACK)
    raise Error, "Configure as credenciais do SUAP no servidor." unless @client_id && @secret
  end

  def authorization_url(state, verifier)
    query = { client_id: @client_id, redirect_uri: @callback, response_type: "code", state: state,
              code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false), code_challenge_method: "S256" }
    query[:scope] = ENV["SUAP_SCOPE"] if ENV["SUAP_SCOPE"].present?
    "#{ORIGIN}/o/authorize/?#{URI.encode_www_form(query)}"
  end

  def author_profile(code, verifier)
    exchange = Net::HTTP::Post.new("/o/token/")
    exchange.set_form_data(grant_type: "authorization_code", code: code, redirect_uri: @callback,
                           client_id: @client_id, client_secret: @secret, code_verifier: verifier)
    token = request_json(exchange)["access_token"]
    raise Error, "O SUAP não retornou um token válido." unless token.is_a?(String) && token.match?(/\A[!-~]+\z/)

    summary = fetch_profile(token, "/api/rh/meus-dados/")
    name = usable_name(summary["nome"])
    begin
      profile = fetch_profile(token, "/api/rh/eu/")
    rescue Error
      raise unless name
      # Some applications can read only the summary profile.
      profile = {}
    end
    name ||= %w[nome_social nome nome_registro].lazy.map { |key| usable_name(profile[key]) }.find(&:present?)
    raise Error, "O SUAP autenticou sua conta, mas não forneceu um nome válido." unless name

    identifier = if summary["id"].is_a?(Integer)
      "id:#{summary["id"]}"
    elsif profile["identificacao"].is_a?(String) && profile["identificacao"].strip.present?
      "identificacao:#{profile["identificacao"].strip}"
    end
    unless identifier
      raise Error, "O SUAP precisa liberar a identificação da conta para publicar e votar."
    end
    { name: name, photo: photo_url(profile["foto"]), key: Digest::SHA256.hexdigest(identifier) }
  end

  private

  def photo_url(value)
    return unless value.is_a?(String) && value.strip.present?

    uri = URI.join("#{ORIGIN}/", value.strip)
    return unless uri.is_a?(URI::HTTPS) && uri.host == URI(ORIGIN).host && uri.port == 443
    return if uri.userinfo || uri.query || uri.fragment || uri.path.blank? || uri.to_s.size > 1024

    uri.to_s
  rescue URI::Error
    nil
  end

  def fetch_profile(token, path)
    request = Net::HTTP::Get.new(path)
    request["Authorization"] = "Bearer #{token}"
    request_json(request)
  end

  def usable_name(value)
    return unless value.is_a?(String)

    name = value.strip
    name if name.present? && name.size <= Post::MAX_AUTHOR_LENGTH && !value.include?("\0")
  end

  def request_json(request)
    stage = request.is_a?(Net::HTTP::Post) ? "troca do código" : "consulta ao perfil"
    request["Accept"] = "application/json"
    response = Net::HTTP.start(URI(ORIGIN).host, 443, use_ssl: true, open_timeout: 5, read_timeout: 8, write_timeout: 5) do |http|
      http.request(request)
    end
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "O SUAP recusou a #{stage} (HTTP #{response.code})."
    end
    data = JSON.parse(response.body)
    raise Error, "Resposta inesperada do SUAP na #{stage}." unless data.is_a?(Hash)
    data
  rescue JSON::ParserError
    raise Error, "O SUAP retornou uma resposta ilegível na #{stage}."
  rescue Timeout::Error, IOError, SocketError, SystemCallError, OpenSSL::SSL::SSLError, Net::ProtocolError
    raise Error, "Falha de conexão com o SUAP na #{stage}."
  end
end
