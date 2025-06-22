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

  def user_stream
    unless block_given?
      raise ArgumentError
    end

    @conn.get('/api/v1/streaming/user') do |res|
      res.options.on_data = proc do |event_type, data|
        yield(event_type, data)
      end
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end

  def health_stream
    unless block_given?
      raise ArgumentError
    end

    @conn.get('/api/v1/streaming/health') do |res|
      res.options.on_data = proc do |event_type, data|
        yield(event_type, data)
      end
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError
    raise ConnectionFailedError
  end
end
