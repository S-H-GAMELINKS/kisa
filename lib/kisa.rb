# frozen_string_literal: true

require 'faraday'
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

  private

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
