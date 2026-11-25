# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_AUTH=clearance (the default).

gem "bcrypt", "~> 3.1.7"
gem "clearance", "~> 2.0"

after_bundle do
  generate_deferring_readme "clearance:install"
  generate "clearance:views"

  create_file "app/models/user.rb", force: true do
    <<~RUBY
      class User < ApplicationRecord
        include Clearance::User

        DEFAULT_PASSWORD = "correct-horse-battery".freeze

        validates :email, presence: true, uniqueness: true
      end
    RUBY
  end

  create_file "app/controllers/sessions_controller.rb", force: true do
    <<~RUBY
      class SessionsController < Clearance::SessionsController
      end
    RUBY
  end

  route <<~RUBY
    resources :passwords, controller: "clearance/passwords", only: [:new, :create, :edit, :update]
    resource :session, controller: "sessions", only: [:new, :create, :destroy]
    resources :users, controller: "clearance/users", only: [:new, :create]
  RUBY

  # clearance:install already injects `include Clearance::Controller` into
  # ApplicationController — only the require_login gate is ours to add.
  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    "  before_action :require_login\n\n"
  end
end
