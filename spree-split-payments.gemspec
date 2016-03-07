# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree-split-payments'
  s.version     = '3.0.0'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Manish Kangia'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'

  s.summary   = 'Provides the feature for a Spree store to allow user to club payment methods to pay for the order'
  s.license   = 'MIT'

  s.files       = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.7'

  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'coffee-script'
end
