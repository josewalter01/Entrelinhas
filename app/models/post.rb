class Post < ApplicationRecord
  FILE_TYPES = { "image/jpeg" => %w[jpg jpeg], "image/png" => %w[png],
                 "image/webp" => %w[webp], "application/pdf" => %w[pdf] }.freeze
  FEED_TYPES = {
    "imagens" => FILE_TYPES.keys.grep(%r{\Aimage/}),
    "documentos" => ["application/pdf"]
  }.freeze
  MAX_AUTHOR_LENGTH = 100
  MAX_BODY_LENGTH = 30_000
  MAX_FILE_SIZE = 8.megabytes

  has_one_attached :attachment
  normalizes :author_name, with: ->(name) { name.strip }
  validates :author_name, presence: true, length: { maximum: MAX_AUTHOR_LENGTH }
  validates :published_on, :body, presence: true
  validates :body, length: { maximum: MAX_BODY_LENGTH }
  validates :body, :author_name, format: { without: /\x00/, message: "contém um caractere nulo." }
  validate :valid_attachment

  scope :chronological, -> { order(published_on: :desc, created_at: :desc, id: :desc) }

  def self.for_feed(filter, order: nil)
    score = "(SELECT COALESCE(SUM(votes.value), 0) FROM votes WHERE votes.post_id = posts.id)"
    posts = select("posts.*, #{score} AS vote_score")
    posts = posts.order(Arel.sql("vote_score DESC")) unless order == "recentes"
    posts = posts.chronological.preload(attachment_attachment: :blob)
    types = FEED_TYPES[filter]
    return posts unless types

    posts.joins(:attachment_blob).where(active_storage_blobs: { content_type: types })
  end

  # Check the bytes without filename or client MIME hints before accepting an upload.
  def receive_upload(file)
    @upload_error = nil
    return if file.blank?

    if !file.is_a?(ActionDispatch::Http::UploadedFile)
      @upload_error = "deve ser um arquivo enviado pelo formulário."
    elsif file.size > MAX_FILE_SIZE
      @upload_error = "deve ter até 8 MiB."
    else
      attach_verified_upload(file)
    end
  end

  private

  def attach_verified_upload(file)
    mime = Marcel::MimeType.for(file.tempfile)
    extension = File.extname(file.original_filename).delete_prefix(".").downcase
    unless FILE_TYPES.fetch(mime, []).include?(extension)
      @upload_error = "deve ser JPEG, PNG, WebP ou PDF com extensão correspondente."
      return
    end

    file.tempfile.rewind
    attachment.attach(io: file.tempfile, filename: file.original_filename, content_type: mime, identify: false)
  end

  def valid_attachment
    errors.add(:attachment, @upload_error) if @upload_error
    return unless attachment.attached?

    errors.add(:attachment, "tem formato incompatível.") unless FILE_TYPES.key?(attachment.content_type)
    errors.add(:attachment, "deve ter até 8 MiB.") if attachment.byte_size > MAX_FILE_SIZE
  end
end
