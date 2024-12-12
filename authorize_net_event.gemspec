$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "authorize_net_event/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "authorize_net_event"
  s.version     = AuthorizeNetEvent::VERSION
  s.license     = "MIT"
  s.authors     = ["David Reese"]
  s.email       = "david@whatcould.com"
  s.homepage    = "https://github.com/whatcould/authorize_net_event"
  s.summary     = "Authorize.net Webhook Notifications integration for Rails applications."
  s.description = "Authorize.net Webhook Notifications integration for Rails applications."

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- Appraisals {spec,gemfiles}/*`.split("\n")

  s.add_dependency "activesupport", ">= 6.1"
  s.add_dependency "ostruct", ">= 0.6.1"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "rails", [">= 6.1"]
  s.add_development_dependency "rake"
  s.add_development_dependency "webmock"
end
