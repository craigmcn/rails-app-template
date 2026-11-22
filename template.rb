# frozen_string_literal: true
#
# Rails application template — invoked via `rails new APP_NAME -m template.rb`.
# Normally run through bin/new-rails-app, which also sets the SCAFFOLD_* env
# vars this template reads (rails new's own -m mechanism has no clean way to
# pass custom argv through, so ENV is the handoff point).

LIB = File.expand_path("lib/template", __dir__)

AUTH = ENV.fetch("SCAFFOLD_AUTH", "clearance")
TEST = ENV.fetch("SCAFFOLD_TEST", "minitest")
SKIP_ADMIN = ENV.fetch("SCAFFOLD_SKIP_ADMIN", "false") == "true"
CSS = ENV.fetch("SCAFFOLD_CSS", "bootstrap")
JAVASCRIPT = ENV.fetch("SCAFFOLD_JAVASCRIPT", "esbuild")
ACTIVE_STORAGE = ENV.fetch("SCAFFOLD_ACTIVE_STORAGE", "false") == "true"
ACTION_TEXT = ENV.fetch("SCAFFOLD_ACTION_TEXT", "false") == "true"
RACK_ATTACK = ENV.fetch("SCAFFOLD_RACK_ATTACK", "true") == "true"
PAGY = ENV.fetch("SCAFFOLD_PAGY", "true") == "true"

VIEW_STYLE = case CSS
             when "bootstrap" then "bootstrap"
             when "tailwind" then "tailwind"
             else "minimal"
             end

# Written synchronously (not in after_bundle) so it's on disk before Rails'
# own --css/--javascript setup runs any `yarn` commands.
create_file ".yarnrc.yml", "nodeLinker: node-modules\n", force: true

# json 3.x changed JSON.parse's call signature in a way Rails 8.1.3.1's
# ActiveSupport isn't compatible with yet — every encrypted cookie (session,
# CSRF) is JSON-decoded on every request via
# ActiveSupport::Messages::Metadata#deserialize_from_json, so an
# unconstrained Gemfile resolves to json 3.x and every request past the
# first one (the first has no cookies yet to decode) raises
# `ArgumentError: wrong number of arguments (given 2, expected 1)` deep
# inside JSON.parse — surfacing as an unstyled, traceless 500 even in
# development, since the exact same JSON decode also breaks rendering
# Rails' own debug-exceptions error page. Reproduced and confirmed fixed
# against a real scaffolded app; revisit once Rails/ActiveSupport
# officially supports json 3.x.
gem "json", "< 3"

apply "#{LIB}/support.rb"
apply "#{LIB}/db_credentials.rb"
apply "#{LIB}/db_create.rb"
apply "#{LIB}/port.rb"
apply "#{LIB}/puma_dev_threads.rb"
apply "#{LIB}/pundit.rb"
apply(AUTH == "devise" ? "#{LIB}/auth_devise.rb" : "#{LIB}/auth_clearance.rb")
apply "#{LIB}/roles.rb"
apply "#{LIB}/admin.rb" unless SKIP_ADMIN
apply "#{LIB}/rack_attack.rb" if RACK_ATTACK
# bin/new-rails-app already forces ACTIVE_STORAGE on whenever ACTION_TEXT is
# set, but that guard lives in the CLI, not here — anyone invoking
# `rails new -m template.rb` directly (or hand-setting SCAFFOLD_* env vars)
# would otherwise get Action Text applied without the Active Storage tables
# its rich_text_content references. Guard here too, not just in the CLI.
apply "#{LIB}/active_storage.rb" if ACTIVE_STORAGE || ACTION_TEXT
apply "#{LIB}/action_text.rb" if ACTION_TEXT
apply "#{LIB}/pagy.rb" if PAGY
apply "#{LIB}/services.rb"
apply "#{LIB}/view_styles/#{VIEW_STYLE}.rb"
apply(TEST == "rspec" ? "#{LIB}/test_rspec.rb" : "#{LIB}/test_minitest.rb")
apply "#{LIB}/system_test_driver.rb"
apply "#{LIB}/ci_workflow.rb"
apply "#{LIB}/ci.rb"
apply "#{LIB}/seeds.rb"
apply "#{LIB}/db.rb"
apply "#{LIB}/rubocop.rb"
apply "#{LIB}/readme_claude_md.rb"
