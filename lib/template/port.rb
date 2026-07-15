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

after_bundle do
  # bin/dev runs `foreman start ... --env /dev/null`, deliberately telling
  # foreman not to load .env itself (Rails already loads it once, inside the
  # booted app, via dotenv-rails). But foreman's own PORT default still wins
  # over whatever the app would later read from .env, since it's exported
  # into the child process's environment before Rails ever boots. Source
  # .env in the shell script itself so a developer's chosen PORT actually
  # reaches Puma.
  if File.exist?("bin/dev") && File.read("bin/dev").include?("# Default to port 3000 if not specified")
    gsub_file "bin/dev",
      "# Default to port 3000 if not specified\n",
      "# Load PORT (see .env.sample) before defaulting it below.\n" \
      "[ -f .env ] && set -a && . ./.env && set +a\n\n" \
      "# Default to port 3000 if not specified\n"
  end

  gsub_file "config/environments/development.rb",
    'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }',
    'config.action_mailer.default_url_options = { host: "localhost", port: ENV.fetch("PORT", 3000) }'
end
