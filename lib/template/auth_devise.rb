# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_AUTH=devise.

gem "devise", "~> 5.0"

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

  # Rails' own config/environments/production.rb already has this exact
  # line (its own stock default_url_options, generated before this template
  # ever runs) — gsub_file it in place rather than appending a second one
  # via `application`, which would leave Rails' hardcoded line executing
  # last and silently overriding this. Falls back to "example.com" (Devise's
  # own install-generator default) so the app still boots without HOST set,
  # but a real deploy should set it via whatever mechanism the production
  # platform actually uses for env vars (Heroku config vars, Kamal secrets,
  # systemd environment, etc.) — not .env/.env.sample, which are dev-only
  # and never loaded in production (see ci.rb's dotenv-rails gem_group).
  production_mailer_default = 'config.action_mailer.default_url_options = { host: "example.com" }'
  production_mailer_patched = 'config.action_mailer.default_url_options = { host: ENV.fetch("HOST", "example.com") }'

  gsub_file "config/environments/production.rb", production_mailer_default, production_mailer_patched

  unless File.read("config/environments/production.rb").include?(production_mailer_patched)
    say <<~MESSAGE, :red
      Couldn't confirm config/environments/production.rb's
      default_url_options was patched to read HOST (the expected hardcoded
      `host: "example.com"` line wasn't found). Production mailer links will
      keep pointing at example.com regardless of a HOST env var. See
      lib/template/auth_devise.rb and patch it by hand.
    MESSAGE
  end

  inject_into_class "app/models/user.rb", "User" do
    "  validates :email, presence: true, uniqueness: true\n"
  end
end
