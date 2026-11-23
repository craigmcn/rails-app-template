# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_TEST=rspec. `rails new` runs without
# --skip-test so Rails still generates its CI test jobs (with per-database
# setup) and the capybara/selenium gems; the Minitest test/ dir is removed.

auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")

gem_group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end

after_bundle do
  generate "rspec:install"
  remove_dir "test"

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

        module SignInHelper
          def sign_in_as(user)
            token = SecureRandom.hex(20)
            user.update_columns(remember_token: token)
            cookies[Clearance.configuration.cookie_name] = token
          end
        end

        config.include SignInHelper, type: :request
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

        module SignInHelper
          def sign_in_as(user)
            sign_in(user, scope: :user)
          end
        end

        config.include SignInHelper, type: :request

        config.before(:suite) { Warden.test_mode! }
        config.after(:each) { Warden.test_reset! }
      RUBY
    end
  end
end
