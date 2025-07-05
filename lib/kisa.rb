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
