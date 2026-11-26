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
      RUBY
    else
      <<~RUBY
        require "selenium-webdriver"

        Capybara.register_driver(:selenium_headless_chrome) do |app|
          options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu window-size=1400,1400])
          Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
        end

        # Chrome 158 rejects the "*" origin Capybara 3.40's reset! clears storage with
        # (teamcapybara/capybara#2865). The version check turns this off once a fixed
        # Capybara ships; delete it then.
        if Gem::Version.new(Capybara::VERSION) <= Gem::Version.new("3.40.0")
          require "capybara/selenium/driver"

          Capybara::Selenium::Driver::ChromeDriver.prepend(Module.new do
            private

            def execute_cdp(cmd, params = {})
              super
            rescue Selenium::WebDriver::Error::InvalidArgumentError
              raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

              super("Network.clearBrowserCookies")
              app_origins.each { |origin| super(cmd, params.merge(origin: origin)) }
            end

            # Chrome can only clear storage per origin, so clear the app's own. Not read
            # from the browser: that would trip on an open alert or a second window.
            def app_origins
              urls = [ Capybara.current_session.server&.base_url, Capybara.app_host ].compact
              urls.filter_map { |url| URI(url).then { |uri| uri.origin if uri.is_a?(URI::HTTP) } }.uniq
            end
          end)
        end
      RUBY
    end

  # Rails' driven_by registers :cuprite itself, replacing any driver registered under
  # that name, so options go through it. Ferrum's 10s start timeout flaked on CI.
  driven_by = DRIVER == "cuprite" ? "driven_by :cuprite, options: { process_timeout: 30 }" : "driven_by :selenium_headless_chrome"

  if TEST_FRAMEWORK == "rspec"
    create_file "spec/support/system_tests.rb", force: true do
      <<~RUBY
        require "capybara/rspec"
        #{driver_setup}

        # rspec-rails' SystemExampleGroup always calls `driven_by(DEFAULT_DRIVER)
        # unless @driver` in its own before hook, which runs after this one (this
        # hook is registered globally via RSpec.configure, so it's outer/earlier) —
        # setting Capybara.default_driver alone has no effect since that default
        # driver's own before hook still wins once @driver is unset.
        RSpec.configure do |config|
          config.before(:each, type: :system) do
            #{driven_by}
          end
        end
      RUBY
    end

    # rspec:install comments out rails_helper.rb's spec/support/**/*.rb
    # require by default, so the file above is otherwise never loaded.
    inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
      "  require_relative \"support/system_tests\"\n"
    end

    # type: is explicit so it doesn't depend on rspec-rails inferring it from
    # the spec/system path; an untyped spec would run on rack_test instead.
    create_file "spec/system/home_spec.rb", force: true do
      <<~RUBY
        require "rails_helper"

        RSpec.describe "Home", type: :system do
          it "shows the app title" do
            visit root_path
            expect(page).to have_selector("h1", text: #{app_title.inspect})
          end
        end
      RUBY
    end
  else
    empty_directory "test/system"

    create_file "test/application_system_test_case.rb", force: true do
      <<~RUBY
        require "test_helper"
        #{driver_setup}
        class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
          #{driven_by}
        end
      RUBY
    end

    create_file "test/system/home_test.rb", force: true do
      <<~RUBY
        require "application_system_test_case"

        class HomeTest < ApplicationSystemTestCase
          test "visiting the home page" do
            visit root_path
            assert_selector "h1", text: #{app_title.inspect}
          end
        end
      RUBY
    end
  end
end
