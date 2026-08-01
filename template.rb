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

VIEW_STYLE = case CSS
             when "bootstrap" then "bootstrap"
             when "tailwind" then "tailwind"
             else "minimal"
             end

# Written synchronously (not in after_bundle) so it's on disk before Rails'
# own --css/--javascript setup runs any `yarn` commands.
create_file ".yarnrc.yml", "nodeLinker: node-modules\n", force: true

apply "#{LIB}/support.rb"
apply "#{LIB}/db_create.rb"
apply "#{LIB}/port.rb"
apply "#{LIB}/pundit.rb"
apply(AUTH == "devise" ? "#{LIB}/auth_devise.rb" : "#{LIB}/auth_clearance.rb")
apply "#{LIB}/roles.rb"
apply "#{LIB}/admin.rb" unless SKIP_ADMIN
apply "#{LIB}/services.rb"
apply "#{LIB}/view_styles/#{VIEW_STYLE}.rb"
apply(TEST == "rspec" ? "#{LIB}/test_rspec.rb" : "#{LIB}/test_minitest.rb")
apply "#{LIB}/ci.rb"
apply "#{LIB}/seeds.rb"
apply "#{LIB}/db.rb"
apply "#{LIB}/readme_claude_md.rb"
