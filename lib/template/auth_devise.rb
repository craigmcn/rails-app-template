# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_AUTH=devise.

gem "devise"

after_bundle do
  generate "devise:install"
  generate "devise", "User"
  generate "devise:views"

  inject_into_file "config/environments/development.rb", after: "Rails.application.configure do\n" do
    "  config.action_mailer.default_url_options = { host: \"localhost\", port: ENV.fetch(\"PORT\", 3000) }\n"
  end

  application 'config.action_mailer.default_url_options = { host: "example.com" }', env: "production"

  inject_into_class "app/models/user.rb", "User" do
    "  validates :email, presence: true, uniqueness: true\n"
  end
end
