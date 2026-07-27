# frozen_string_literal: true
# Applied by template.rb — always runs. Adds a flattened "service object"
# convention (single layer, no separate Actions layer): controllers call
# services directly and services may call each other to orchestrate more
# complex operations. Authorization stays where it already lives (Pundit
# policies in the controller); a service's own "signature" — the shape of
# the args hash it accepts — is validated via dry-schema.

test = ENV.fetch("SCAFFOLD_TEST", "minitest")
test_dir = test == "rspec" ? "spec" : "test"
test_template = test == "rspec" ? "service_spec.rb.tt" : "service_test.rb.tt"
test_suffix = test == "rspec" ? "_spec" : "_test"
test_example_path = test == "rspec" ? "spec/services/authentication/create_session_spec.rb" : "test/services/authentication/create_session_test.rb"

gem "dry-schema"

after_bundle do
  # lib/generators/service/service_generator.rb (created below) defines a
  # plain, unnamespaced ServiceGenerator, per Rails' own generator
  # convention — but Rails 7.1+'s default config.autoload_lib(ignore: %w[
  # assets tasks]) hands `lib/generators` to Zeitwerk too, which eager-loads
  # it in production and expects a namespaced Generators::Service::
  # ServiceGenerator constant instead, crashing production boot entirely.
  # Rails' own generator lookup already loads generator files on demand, so
  # Zeitwerk should never manage this directory.
  gsub_file "config/application.rb",
    "config.autoload_lib(ignore: %w[assets tasks])",
    'config.autoload_lib(ignore: %w[assets tasks generators])'

  unless File.read("config/application.rb").include?('config.autoload_lib(ignore: %w[assets tasks generators])')
    say <<~MESSAGE, :red
      Couldn't confirm config/application.rb's autoload_lib was patched to
      ignore lib/generators — the expected `config.autoload_lib(ignore: %w[
      assets tasks])` line wasn't found. Without this, the app will crash on
      boot under RAILS_ENV=production (or anywhere eager loading is on). See
      lib/template/services.rb and patch it by hand.
    MESSAGE
  end

  create_file "app/services/application_service.rb" do
    <<~RUBY
      # Base class for service objects: single-purpose units of business
      # logic that controllers call directly, and that may call each other
      # to orchestrate more complex operations.
      #
      # Generate one with:
      #   rails generate service Authentication::CreateSession
      class ApplicationService
        Error = Class.new(StandardError) do
          attr_reader :details

          def initialize(message, details: {})
            super(message)
            @details = details
          end
        end

        def self.call(args = {}, deps = {})
          instance = effective_instance(args, deps)
          validate!(args) if instance.instance_of?(self)
          instance.call(args, deps)
        end

        # Defines this service's dry-schema argument validation. Usage:
        #   SCHEMA = define_schema do
        #     required(:email).filled(:string)
        #   end
        def self.define_schema(&block)
          Dry::Schema.Params(&block)
        end

        def self.validate!(args)
          return unless const_defined?(:SCHEMA)

          result = const_get(:SCHEMA).call(args)
          raise self::Error.new("\#{name} received invalid arguments", details: result.errors.to_h) if result.failure?
        end

        # Lets tests override a nested service call, e.g.
        #   Authentication::CreateSession.call(args, "Authentication::FindUser" => ->(args, _deps) { ... })
        #
        # For an override to reach a nested call, the calling service's own
        # #call must forward its `deps` argument to that nested `.call` —
        # an override only takes effect at the level it's passed to.
        # Overriding a class this way also skips that class's own
        # validate!, since the override replaces its behavior entirely.
        def self.effective_instance(args, deps)
          deps[name] || deps[name.to_sym] || new(args, deps)
        end

        def initialize(args = {}, deps = {})
          @args = args
          @deps = deps
        end

        private

        def failure!(message, details: {})
          raise self.class::Error.new(message, details: details)
        end
      end
    RUBY
  end

  create_file "lib/generators/service/USAGE" do
    <<~USAGE
      Description:
          Generate a new service object (a subclass of ApplicationService).
          Services are single-purpose units of business logic that
          controllers call directly, and that may call each other to
          orchestrate more complex operations.

      Example:
          rails generate service Authentication::CreateSession

          This will create:
              app/services/authentication/create_session.rb
              #{test_example_path}
    USAGE
  end

  create_file "lib/generators/service/service_generator.rb" do
    <<~RUBY
      require "rails/generators"

      class ServiceGenerator < Rails::Generators::NamedBase
        source_root File.expand_path("templates", __dir__)

        def create_service_file
          template "service.rb.tt", File.join("app/services", class_path, "\#{file_name}.rb")
        end

        def create_test_file
          test_path = File.join("#{test_dir}/services", class_path, "\#{file_name}#{test_suffix}.rb")
          template "#{test_template}", test_path
        end
      end
    RUBY
  end

  create_file "lib/generators/service/templates/service.rb.tt" do
    <<~ERB
      <% module_namespacing do -%>
      class <%= class_name %> < ApplicationService
        Error = Class.new(ApplicationService::Error)

        # SCHEMA = define_schema do
        #   required(:some_arg).filled(:string)
        # end

        # @param args [Hash]
        # @param deps [Hash] service-name => override, used to stub nested calls in
        #   tests — forward `deps` to any nested `.call` so overrides reach it
        def call(args, deps)
          failure!("<%= class_name %>\#call is not yet implemented")
        end
      end
      <% end -%>
    ERB
  end

  if test == "rspec"
    create_file "lib/generators/service/templates/service_spec.rb.tt" do
      <<~ERB
        require "rails_helper"

        <% module_namespacing do -%>
        RSpec.describe <%= class_name %> do
          it "is not yet implemented" do
            expect { described_class.call({}) }.to raise_error(<%= class_name %>::Error)
          end
        end
        <% end -%>
      ERB
    end
  else
    create_file "lib/generators/service/templates/service_test.rb.tt" do
      <<~ERB
        require "test_helper"

        <% module_namespacing do -%>
        class <%= class_name %>Test < ActiveSupport::TestCase
          test "not yet implemented" do
            assert_raises(<%= class_name %>::Error) { <%= class_name %>.call({}) }
          end
        end
        <% end -%>
      ERB
    end
  end
end
