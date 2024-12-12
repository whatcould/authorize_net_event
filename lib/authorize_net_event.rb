require "active_support/notifications"
require "authorize_net_event/engine" if defined?(Rails)

module AuthorizeNetEvent
  class << self
    attr_accessor :adapter, :backend, :namespace, :event_filter
    attr_accessor :apple_root_cert_path
    attr_reader :signing_secrets

    def configure(&block)
      raise ArgumentError, "must provide a block" unless block_given?
      block.arity.zero? ? instance_eval(&block) : yield(self)
    end
    alias :setup :configure

    def instrument(event)
      event = event_filter.call(event)
      backend.instrument namespace.call(event.notificationType), event if event
    end

    def subscribe(name, callable = nil, &block)
      callable ||= block
      backend.subscribe namespace.to_regexp(name), adapter.call(callable)
    end

    def all(callable = nil, &block)
      callable ||= block
      subscribe nil, callable
    end

    def listening?(name)
      namespaced_name = namespace.call(name)
      backend.notifier.listening?(namespaced_name)
    end

    def signing_secret=(value)
      @signing_secrets = Array(value).compact
    end
    alias signing_secrets= signing_secret=

    def signing_secret
      self.signing_secrets && self.signing_secrets.first
    end

  end

  class Namespace < Struct.new(:value, :delimiter)
    def call(name = nil)
      "#{value}#{delimiter}#{name}"
    end

    def to_regexp(name = nil)
      %r{^#{Regexp.escape call(name)}}
    end
  end

  class NotificationAdapter < Struct.new(:subscriber)
    def self.call(callable)
      new(callable)
    end

    def call(*args)
      payload = args.last
      subscriber.call(payload)
    end
  end

  class Error < StandardError
    attr_reader :message, :code, :error, :http_body, :http_headers, :http_status, :json_body, :request_id

    def initialize(message = nil, http_status: nil, http_body: nil,
                  json_body: nil, http_headers: nil, code: nil)
      @message = message
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @idempotent_replayed = @http_headers["idempotent-replayed"] == "true"
      @json_body = json_body
      @code = code
      @request_id = @http_headers["request-id"]
    end
  end

  class UnauthorizedError < Error; end
  class ProcessError < Error; end
  class SignatureVerificationError < Error
    attr_accessor :sig_header

    def initialize(message, sig_header, http_body: nil, http_headers: nil)
      super(message, http_body: http_body)
      @sig_header = sig_header
    end
  end

  self.adapter = NotificationAdapter
  self.backend = ActiveSupport::Notifications
  self.namespace = Namespace.new("authorize_net_event", ".")
  self.event_filter = lambda { |event| event }
end
