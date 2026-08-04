# frozen_string_literal: true
# Applied by template.rb — always runs. Rails' own config/puma.rb already
# reads ENV["PORT"] (falling back to 3000), but two other places hardcode
# 3000 and never look at that env var: bin/dev (added by --css/--javascript's
# cssbundling-rails/jsbundling-rails generators) and the development mailer's
# default_url_options. This makes PORT the single dev-facing knob for all
# three, and documents it in a committed .env.sample.

create_file ".env.sample", <<~ENV
  # Copy this file to .env (gitignored) and edit it to override settings for
  # your machine. PORT is read by bin/dev and by the development mailer's
  # default_url_options in config/environments/development.rb.
  PORT=3000
ENV

create_file ".env", <<~ENV
  PORT=3000
ENV

# Rails' own generated .gitignore has `/.env*`, which also matches
# .env.sample — meaning the "committed template" .env.sample documents
# above would never actually reach the repo. Un-ignore just that one file.
append_to_file ".gitignore", <<~GITIGNORE

  # .env.sample is the committed template for .env — un-ignore it despite
  # the /.env* rule above.
  !/.env.sample
GITIGNORE

after_bundle do
  # bin/dev runs `foreman start ... --env /dev/null`, deliberately telling
  # foreman not to load .env itself (Rails already loads it once, inside the
  # booted app, via dotenv-rails). But foreman's own PORT default still wins
  # over whatever the app would later read from .env, since it's exported
  # into the child process's environment before Rails ever boots. Source
  # .env (and .env.local, dotenv-rails' machine-local override file) in the
  # shell script itself so a developer's chosen PORT actually reaches Puma.
  # This is a partial, not full, mirror of dotenv-rails' cascade (which also
  # has .env.development[.local] — see #5) but covers the common case.
  bin_dev_marker = "# Default to port 3000 if not specified\n"

  if File.exist?("bin/dev") && File.read("bin/dev").include?(bin_dev_marker)
    gsub_file "bin/dev",
      bin_dev_marker,
      "# Load PORT (see .env.sample) before defaulting it below.\n" \
      "[ -f .env ] && set -a && . ./.env && set +a\n" \
      "[ -f .env.local ] && set -a && . ./.env.local && set +a\n\n" \
      "#{bin_dev_marker}"

    verified_inject "bin/dev", "[ -f .env ] && set -a && . ./.env && set +a", <<~MESSAGE
      Couldn't confirm bin/dev was patched to load .env before Puma boots
      (the expected marker text wasn't found after editing). PORT will
      still reach Puma once Rails boots via config/puma.rb, but bin/dev's
      own foreman default may win over .env for the initial bind. Rails'
      --css/--javascript generators may have changed bin/dev's wording —
      see lib/template/port.rb and patch it by hand.
    MESSAGE
  end

  mailer_default = 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'
  mailer_patched = 'config.action_mailer.default_url_options = { host: "localhost", port: ENV.fetch("PORT", 3000) }'

  gsub_file "config/environments/development.rb", mailer_default, mailer_patched

  verified_inject "config/environments/development.rb", mailer_patched, <<~MESSAGE
    Couldn't confirm config/environments/development.rb's
    default_url_options was patched to read PORT (the expected hardcoded
    `port: 3000` line wasn't found). The development mailer will keep
    using port 3000 regardless of PORT in .env. See lib/template/port.rb
    and patch it by hand.
  MESSAGE
end
