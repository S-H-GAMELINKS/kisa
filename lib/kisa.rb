# frozen_string_literal: true

require 'faraday'
require_relative "kisa/version"

class Kisa
  class Error < StandardError; end

  def initialize(url:, headers:)
    raise ArgumentError if url.nil?
    raise ArgumentError if headers.nil?

    @conn = Faraday.new(url:, headers:)
  end

  def user_stream
    @conn.get('/api/v1/streaming/user') do |res|
      res.options.on_data = proc do |event_type, data|
        yield(event_type, data)
      end
    end
  end
end
