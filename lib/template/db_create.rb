# frozen_string_literal: true
# Applied by template.rb — first, before pundit/auth/roles. Clearance's and
# Devise's install generators query the database directly (e.g. Clearance's
# `users_table_exists?`) while generating, so the database has to exist
# before those generators run, not just before the final db.rb migrate/seed
# step. db:create is safe to call again later (db:prepare no-ops if the
# database already exists).

after_bundle do
  rails_command "db:create", capture: false
end
