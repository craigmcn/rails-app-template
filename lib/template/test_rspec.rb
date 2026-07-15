# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_TEST=rspec. `bin/new-rails-app`
# passes --skip-test to `rails new` in this case, so Minitest's scaffold
# was never generated.

auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")

gem_group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

after_bundle do
  generate "rspec:install"

  create_file "spec/factories/roles.rb", force: true do
    <<~RUBY
      FactoryBot.define do
        factory :role do
          sequence(:name) { |n| "role-\#{n}" }

          trait :member do
            name { "member" }
          end

          trait :moderator do
            name { "moderator" }
          end

          trait :admin do
            name { "admin" }
          end
        end
      end
    RUBY
  end

  if auth == "clearance"
    create_file "spec/factories/users.rb", force: true do
      <<~RUBY
        FactoryBot.define do
          factory :user do
            sequence(:email) { |n| "user\#{n}@example.com" }
            password { User::DEFAULT_PASSWORD }

            trait :moderator do
              after(:create) { |user| user.roles << FactoryBot.create(:role, :moderator) }
            end

            trait :admin do
              after(:create) { |user| user.roles << FactoryBot.create(:role, :admin) }
            end
          end
        end
      RUBY
    end

    inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
      <<~RUBY
        config.include FactoryBot::Syntax::Methods

        config.before(:each, type: :request) do |example|
          next unless example.metadata[:as]

          user = example.metadata[:as]
          token = SecureRandom.hex(20)
          user.update_columns(remember_token: token)
          cookies[Clearance.configuration.cookie_name] = token
        end
      RUBY
    end
  else
    create_file "spec/factories/users.rb", force: true do
      <<~RUBY
        FactoryBot.define do
          factory :user do
            sequence(:email) { |n| "user\#{n}@example.com" }
            password { "correct-horse-battery" }

            trait :moderator do
              after(:create) { |user| user.roles << FactoryBot.create(:role, :moderator) }
            end

            trait :admin do
              after(:create) { |user| user.roles << FactoryBot.create(:role, :admin) }
            end
          end
        end
      RUBY
    end

    inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
      <<~RUBY
        config.include FactoryBot::Syntax::Methods
        config.include Warden::Test::Helpers
        config.include Devise::Test::IntegrationHelpers, type: :request

        config.before(:suite) { Warden.test_mode! }
        config.after(:each) { Warden.test_reset! }
      RUBY
    end
  end
end
