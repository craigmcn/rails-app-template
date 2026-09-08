# frozen_string_literal: true
# Applied by template.rb — always runs, after the test framework
# (test_minitest.rb/test_rspec.rb) is set up. Writes the system-test driver
# setup from scratch for both frameworks rather than patching Rails'
# generated file in place: `rspec:install` never sets one up at all, and
# (as of Rails 8.1) `rails new` no longer scaffolds test/system by default
# either, so there's nothing reliable to anchor a gsub/inject_into_file on.

DRIVER = ENV.fetch("SCAFFOLD_SYSTEM_TEST_DRIVER", "selenium")
TEST_FRAMEWORK = ENV.fetch("SCAFFOLD_TEST", "minitest")

gem "cuprite", "~> 0.15", group: :test if DRIVER == "cuprite"

after_bundle do
  driver_setup =
    if DRIVER == "cuprite"
      <<~RUBY
        require "capybara/cuprite"

        Capybara.register_driver(:cuprite) do |app|
          Capybara::Cuprite::Driver.new(app, window_size: [1400, 1400])
        end
      RUBY
    else
      <<~RUBY
        require "selenium-webdriver"

        Capybara.register_driver(:selenium_headless_chrome) do |app|
          options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu window-size=1400,1400])
          Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
        end
      RUBY
    end

  driver_name = DRIVER == "cuprite" ? :cuprite : :selenium_headless_chrome

  if TEST_FRAMEWORK == "rspec"
    create_file "spec/support/system_tests.rb", force: true do
      <<~RUBY
        require "capybara/rspec"
        #{driver_setup}
        Capybara.default_driver = Capybara.javascript_driver = :#{driver_name}
      RUBY
    end
  else
    empty_directory "test/system"

    create_file "test/application_system_test_case.rb", force: true do
      <<~RUBY
        require "test_helper"
        #{driver_setup}
        class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
          driven_by :#{driver_name}
        end
      RUBY
    end
  end
end
