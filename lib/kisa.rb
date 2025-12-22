# frozen_string_literal: true

require 'faraday'
require 'json'
require 'cgi'
require_relative "kisa/version"

class Kisa
  class Error < StandardError; end
  class ConnectionFailedError < StandardError; end

  def initialize(url:, headers:)
    raise ArgumentError if url.nil?
    raise ArgumentError if headers.nil?

    @conn = Faraday.new(url:, headers:)
  end

  def user_stream(&block)
    stream('/api/v1/streaming/user', &block)
  end

  def health_stream(&block)
    stream('/api/v1/streaming/health', &block)
  end

  def notification_stream(&block)
    stream('/api/v1/streaming/user/notification', &block)
  end

  def public_stream(&block)
    stream('/api/v1/streaming/public', &block)
  end

  def public_local_stream(&block)
    stream('/api/v1/streaming/public/local', &block)
  end

  def public_remote_stream(&block)
    stream('/api/v1/streaming/public/remote', &block)
  end

  def direct_stream(&block)
    stream('/api/v1/streaming/direct', &block)
  end

  def hashtag_stream(hashtag, &block)
    raise ArgumentError, "hashtag is required" if hashtag.nil? || hashtag.to_s.empty?

    # Remove # prefix if present
    hashtag = hashtag.sub(/^#/, '')
    encoded_hashtag = CGI.escape(hashtag)

    stream("/api/v1/streaming/hashtag?tag=#{encoded_hashtag}", &block)
  end

  def hashtag_local_stream(hashtag, &block)
    raise ArgumentError, "hashtag is required" if hashtag.nil? || hashtag.to_s.empty?

    # Remove # prefix if present
    hashtag = hashtag.sub(/^#/, '')
    encoded_hashtag = CGI.escape(hashtag)

    stream("/api/v1/streaming/hashtag/local?tag=#{encoded_hashtag}", &block)
  end

  def list_stream(list_id, &block)
    raise ArgumentError, "list_id is required" if list_id.nil? || list_id.to_s.empty?

    stream("/api/v1/streaming/list?list=#{list_id}", &block)
  end

  def hashtag_timeline(hashtag, params = {})
    raise ArgumentError, "hashtag is required" if hashtag.nil? || hashtag.empty?

    # Remove # prefix if present
    hashtag = hashtag.sub(/^#/, '')

    # Build query parameters
    query_params = build_query_params(params)
    url = "/api/v1/timelines/tag/#{hashtag}"
    url += "?#{query_params}" unless query_params.empty?

    response = @conn.get(url)

    unless response.success?
      raise Error, "Failed to fetch hashtag timeline: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def boost(status_id, visibility: 'public')
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    valid_visibilities = %w[public unlisted private direct]
    unless valid_visibilities.include?(visibility)
      raise ArgumentError, "visibility must be one of: #{valid_visibilities.join(', ')}"
    end

    body = { visibility: visibility }

    response = @conn.post("/api/v1/statuses/#{status_id}/reblog", body.to_json, { 'Content-Type' => 'application/json' })

    unless response.success?
      raise Error, "Failed to boost status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def favourite(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.post("/api/v1/statuses/#{status_id}/favourite")

    unless response.success?
      raise Error, "Failed to favourite status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def get_status(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.get("/api/v1/statuses/#{status_id}")

    unless response.success?
      raise Error, "Failed to get status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def delete_status(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.delete("/api/v1/statuses/#{status_id}")

    unless response.success?
      raise Error, "Failed to delete status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def unfavourite(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.post("/api/v1/statuses/#{status_id}/unfavourite")

    unless response.success?
      raise Error, "Failed to unfavourite status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def unboost(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.post("/api/v1/statuses/#{status_id}/unreblog")

    unless response.success?
      raise Error, "Failed to unboost status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def bookmark(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.post("/api/v1/statuses/#{status_id}/bookmark")

    unless response.success?
      raise Error, "Failed to bookmark status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def unbookmark(status_id)
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?

    response = @conn.post("/api/v1/statuses/#{status_id}/unbookmark")

    unless response.success?
      raise Error, "Failed to unbookmark status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def create_status(status, options = {})
    raise ArgumentError, "status is required" if status.nil? || status.to_s.empty?

    body = { status: status }

    allowed_options = %i[media_ids poll in_reply_to_id sensitive spoiler_text visibility language scheduled_at]
    allowed_options.each do |key|
      body[key] = options[key] if options.key?(key)
    end

    response = @conn.post("/api/v1/statuses", body.to_json, { 'Content-Type' => 'application/json' })

    unless response.success?
      raise Error, "Failed to create status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def edit_status(status_id, status, options = {})
    raise ArgumentError, "status_id is required" if status_id.nil? || status_id.to_s.empty?
    raise ArgumentError, "status is required" if status.nil? || status.to_s.empty?

    body = { status: status }

    allowed_options = %i[media_ids poll sensitive spoiler_text language]
    allowed_options.each do |key|
      body[key] = options[key] if options.key?(key)
    end

    response = @conn.put("/api/v1/statuses/#{status_id}", body.to_json, { 'Content-Type' => 'application/json' })

    unless response.success?
      raise Error, "Failed to edit status: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def home_timeline(params = {})
    fetch_timeline('/api/v1/timelines/home', params, %i[max_id since_id min_id limit])
  end

  def public_timeline(params = {})
    fetch_timeline('/api/v1/timelines/public', params, %i[local remote only_media max_id since_id min_id limit])
  end

  def list_timeline(list_id, params = {})
    raise ArgumentError, "list_id is required" if list_id.nil? || list_id.to_s.empty?

    fetch_timeline("/api/v1/timelines/list/#{list_id}", params, %i[max_id since_id min_id limit])
  end

  private

  def build_query_params(params)
    allowed_params = %i[any all none local remote only_media max_id since_id min_id limit]
    filtered_params = params.select { |key, _| allowed_params.include?(key) }

    query_parts = []

    # Handle array parameters (any, all, none)
    %i[any all none].each do |param|
      if filtered_params[param].is_a?(Array)
        filtered_params[param].each do |value|
          query_parts << "#{param}[]=#{CGI.escape(value.to_s)}"
        end
        filtered_params.delete(param)
      end
    end

    # Handle regular parameters
    filtered_params.each do |key, value|
      query_parts << "#{key}=#{CGI.escape(value.to_s)}"
    end

    query_parts.join('&')
  end

  def fetch_timeline(url, params, allowed_params)
    query_params = build_timeline_query_params(params, allowed_params)
    full_url = query_params.empty? ? url : "#{url}?#{query_params}"

    response = @conn.get(full_url)

    unless response.success?
      raise Error, "Failed to fetch timeline: #{response.status} #{response.body}"
    end

    JSON.parse(response.body)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def build_timeline_query_params(params, allowed_params)
    filtered_params = params.select { |key, _| allowed_params.include?(key) }

    filtered_params.map do |key, value|
      "#{key}=#{CGI.escape(value.to_s)}"
    end.join('&')
  end

  def stream(url)
    unless block_given?
      raise ArgumentError
    end

    @conn.get(url) do |res|
      res.options.on_data = proc do |event_type, data|
        yield(event_type, data)
      end
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end
end
