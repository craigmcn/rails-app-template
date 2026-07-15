# frozen_string_literal: true
# Applied by template.rb — always runs. Rails 8's own `rails new` already
# generates .github/workflows/ci.yml (brakeman + rubocop + tests against
# the chosen --database) and adds brakeman/bundler-audit/rubocop-rails-omakase
# to the Gemfile, so this only layers on a few extra dev conveniences.

gem_group :development, :test do
  gem "dotenv-rails"
end

gem_group :development do
  gem "letter_opener"
end
