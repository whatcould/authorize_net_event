Receive Authorize.net's [Webooks](https://developer.authorize.net/api/reference/features/webhooks.html) in your Rails app. Adapted from [StripeEvent](https://github.com/integrallis/stripe_event).

A work in progress.


## Installation

```ruby
# Gemfile
gem 'authorize_net'
```

```ruby
# config/routes.rb
mount AuthorizeNetEvent::Engine, at: '/authorize-net-events' # Chose your own
```
In this case you would set the Webhook endpoint URL in your authorize.net's configuration to  https://example.com/authorize-net-events

## Usage

```ruby
AuthorizeNetEvent.apple_root_cert_path = Rails.root.join('config', 'AppleRootCA-G3.cer')

AuthorizeNetEvent.configure do |events|
  events.all do |event|
    Rails.logger.info event.inspect
    # Handle all event types - logging, etc.
  end
end
```