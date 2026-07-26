# frozen_string_literal: true
# Applied by template.rb — always runs, after every other after_bundle block
# that generates migrations (roles.rb, auth_*.rb). Runs db:prepare so the
# scaffolded app is immediately bootable instead of leaving "create/migrate/
# seed the database" as an undocumented manual step.
#
# rails_command doesn't raise on failure (it shells out and streams the
# subprocess's own output), so a failure here — e.g. Postgres not running —
# just leaves the rest of the app fully scaffolded, with a pointer to finish
# the one remaining step by hand. See README.md > Troubleshooting.

after_bundle do
  @db_prepare_succeeded = rails_command("db:prepare", capture: false)

  unless @db_prepare_succeeded
    say <<~MESSAGE, :red
      db:prepare failed — the app was scaffolded successfully, but the
      database wasn't created/migrated/seeded (see the error above). This is
      almost always a local database server issue, not a problem with the
      generated app. Once the database is reachable, finish setup with:

          bin/rails db:prepare

      See README.md > Troubleshooting in this template's repo for common
      causes and fixes.
    MESSAGE
  end
end
