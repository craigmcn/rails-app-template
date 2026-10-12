# frozen_string_literal: true
# Applied by template.rb when SCAFFOLD_AUTH=devise.

gem "devise", "~> 5.0"

after_bundle do
  # devise:install's own readme ("...manual setup may be required...") prints
  # immediately, then gets buried under every later generator's output — by
  # the time scaffolding finishes it's scrolled off screen. Capture it and
  # replay it at the very end (readme_claude_md.rb) instead of suppressing it,
  # since most of its items (mailer host, views) are already handled here but
  # it's still a useful final sanity-check list. `generate` here shells out to
  # a `rails generate` subprocess, so Ruby-level $stdout redirection doesn't
  # see its output — the real STDOUT fd has to be reopened, not just $stdout.
  require "tempfile"
  tempfile = Tempfile.new("devise_install_output")
  original_stdout_fd = STDOUT.dup
  STDOUT.reopen(tempfile)
  STDOUT.sync = true
  begin
    generate "devise:install"
  ensure
    STDOUT.reopen(original_stdout_fd)
    original_stdout_fd.close
  end
  tempfile.rewind
  output = tempfile.read
  tempfile.close
  tempfile.unlink

  # devise:install's readme is boxed between two "===...=" separator lines —
  # splitting on those lines isolates it from the "create ..." log lines
  # around it, which print immediately as before. split's default limit
  # drops a trailing empty string, which is exactly what's after the second
  # separator (nothing) — pass -1 to keep it, or parts.length never reaches 3.
  parts = output.split(/^=+[ \t]*(?:\r?\n|\z)/, -1)
  if parts.length >= 3
    print parts[0]
    @devise_install_readme = parts[1].strip
    print parts[2]
  else
    print output
  end

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

  # Unlike most patches in this template, a silent failure here isn't just
  # cosmetic drift: it means a production deploy would send password-reset
  # and confirmation emails with links pointing at example.com instead of
  # the real app, regardless of a HOST env var being set. Hard-fail instead
  # of warning, so this can't be scrolled past in scaffold output.
  verified_inject "config/environments/production.rb", production_mailer_patched, <<~MESSAGE, hard_fail: true
    Couldn't confirm config/environments/production.rb's
    default_url_options was patched to read HOST (the expected hardcoded
    `host: "example.com"` line wasn't found). Without this patch,
    password-reset/confirmation emails in production would link to
    example.com regardless of a HOST env var. Aborting scaffolding — see
    lib/template/auth_devise.rb and patch it by hand, then re-run.
  MESSAGE

  inject_into_class "app/models/user.rb", "User" do
    "  validates :email, presence: true, uniqueness: true\n"
  end
end
