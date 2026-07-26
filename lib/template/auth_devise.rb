# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_AUTH=devise.

gem "devise"

after_bundle do
  generate "devise:install"
  generate "devise", "User"
  generate "devise:views"

  # This string must stay byte-identical to what port.rb's gsub_file
  # produces in development.rb — Thor's inject_into_file no-ops when the
  # content is already present, which is what actually prevents a duplicate
  # line here (port.rb's after_bundle runs first). If the two drift apart,
  # this unconditionally inserts a second default_url_options line, and
  # whichever one Ruby evaluates last wins.
  inject_into_file "config/environments/development.rb", after: "Rails.application.configure do\n" do
    "  config.action_mailer.default_url_options = { host: \"localhost\", port: ENV.fetch(\"PORT\", 3000) }\n"
  end

  application 'config.action_mailer.default_url_options = { host: "example.com" }', env: "production"

  inject_into_class "app/models/user.rb", "User" do
    "  validates :email, presence: true, uniqueness: true\n"
  end
end
