require 'ostruct'

module AuthorizeNetEvent
  class AuthorizeNetNotificationController < ActionController::Base
    if Rails.application.config.action_controller.default_protect_from_forgery
      skip_before_action :verify_authenticity_token
    end

    def event
      AuthorizeNetEvent.instrument(verified_payload)
      head :ok
    rescue AuthorizeNetEvent::SignatureVerificationError => e
      log_error(e)
      head :bad_request
    rescue StripeEvent::ProcessError
      head :unprocessable_entity
    end

    def event
      AuthorizeNetEvent.instrument(verified_payload)
      head :ok
    end

    private

    def verified_payload
      payload = request.body.read
      signature = request.headers['X-ANET-Signature'].gsub("sha512=", '')
      possible_secrets = secrets(payload, signature)

      unless possible_secrets.any? { |s|
          expected_sig = OpenSSL::HMAC.hexdigest("SHA512", s, payload).upcase
          secure_compare(expected_sig, signature)
        }
        raise AuthorizeNetEvent::SignatureVerificationError.new(
          "Signature did not match the expected signature for payload",
          signature, http_body: payload, http_headers: request.headers
        )
      end

      data = JSON.parse(payload, object_class: OpenStruct)
      data.type = data.eventType.gsub('net.authorize.', '')
      data
    end

    def secrets(payload, signature)
      return AuthorizeNetEvent.signing_secrets if AuthorizeNetEvent.signing_secret
      raise AuthorizeNetEvent::SignatureVerificationError.new(
              "Cannot verify signature without a `AuthorizeNetEvent.signing_secret`",
              signature, http_body: payload)
    end

    # Constant time string comparison to prevent timing attacks
    # Code borrowed from ActiveSupport
    def secure_compare(str_a, str_b)
      return false unless str_a.bytesize == str_b.bytesize

      l = str_a.unpack "C#{str_a.bytesize}"

      res = 0
      str_b.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end

    def log_error(e)
      logger.error e.message
      e.backtrace.each { |line| logger.error "  #{line}" }
    end
  end
end
