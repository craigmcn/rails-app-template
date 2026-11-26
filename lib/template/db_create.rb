# frozen_string_literal: true
# Applied by template.rb — first, before pundit/auth/roles. Clearance's and
# Devise's install generators query the database directly (e.g. Clearance's
# `users_table_exists?`) while generating, so the database has to exist
# before those generators run, not just before the final db.rb migrate/seed
# step. db:create is safe to call again later (db:prepare no-ops if the
# database already exists).

after_bundle do
  @db_create_succeeded = rails_command "db:create", capture: false

  unless @db_create_succeeded
    note_for_end <<~MESSAGE, :warnings
      db:create failed (see its error in the output above) — the auth
      generators that run after it (Clearance/Devise) query the database
      directly while generating, so they're likely to fail too. This is
      almost always a local database server issue. Once the database is reachable, you can
      re-run this generator, or finish setup by hand with:

          bin/rails db:create
          bin/rails db:prepare

      See README.md > Troubleshooting in this template's repo for common
      causes and fixes.
    MESSAGE
  end
end
