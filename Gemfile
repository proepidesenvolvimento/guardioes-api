source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# Repository for collecting Locale data for Ruby on Rails I18n as well as other interesting, Rails related I18n stuff http://rails-i18n.org
gem 'rails-i18n', '~> 5.1'
# acts_as_paranoid for Rails 3, 4 and 5
gem "paranoia", "~> 2.2"
# A terminal spinner for tasks that have non-deterministic time frame.
gem 'tty-spinner'
# Terminal output styling with intuitive and clean API that doesn't monkey patch String class.
gem 'pastel'
# AccessGranted is a multi-role and whitelist based authorization gem for Rails. And it's lightweight (~300 lines of code)!
gem 'access-granted', '~> 1.1.0'
# Devise Auth token
gem 'devise-jwt'
# Active Model Serializer
gem 'active_model_serializers', '~> 0.10.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.2'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'
gem "roo", "~> 2.8.0"
gem 'roo-xls'
gem 'searchkick'
gem "cancancan"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
# Complete Ruby geocoding solution. http://www.rubygeocoder.com
gem 'geocoder'
gem 'sendgrid-ruby'
# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# Configures an API that communicates with twitter
gem 'twitter'
# Time-based platform-independent background job scheduler daemon for Ruby on Rails.
gem 'crono'
# Sets up the deamon to run alongside crono
gem 'daemons'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 3.5'
  gem 'faker'
  gem 'capybara'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'factory_bot_rails', '~> 4.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'database_cleaner'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
