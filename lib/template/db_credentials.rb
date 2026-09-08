# frozen_string_literal: true
# Applied by template.rb — before db_create.rb, since db:create (and the
# auth generators that query the database right after it) need working
# credentials already in config/database.yml. Only touches anything for
# mysql/trilogy: Rails' own default database.yml for those adapters
# hardcodes `username: root` with a blank password and no fallback to the
# local OS user the way Postgres's trust-auth default does, so a MySQL
# server requiring a real password (or a non-root user) fails db:create
# immediately with no working default to fall back on. Written
# synchronously (not after_bundle), like .yarnrc.yml above, so it's on
# disk before db_create.rb's after_bundle block runs db:create.

DATABASE = ENV.fetch("SCAFFOLD_DATABASE", "postgresql")

if DATABASE.match?(/mysql|trilogy/)
  db_username = ENV.fetch("SCAFFOLD_DB_USERNAME", "root")
  db_password = ENV.fetch("SCAFFOLD_DB_PASSWORD", "")

  # Block form (not a plain string replacement) so a password containing
  # "\" or "$" isn't misinterpreted as a backreference by String#gsub.
  gsub_file("config/database.yml", /^  username: root$/) { "  username: #{db_username}" }
  gsub_file("config/database.yml", /^  password:\s*$/) { "  password: #{db_password}" }

  verified_inject "config/database.yml", "username: #{db_username}", <<~MESSAGE
    Couldn't confirm config/database.yml's username was updated (the
    expected `username: root` line wasn't found — Rails may have changed
    its generated wording). db:create will likely fail against a MySQL
    server that doesn't accept the default root/blank credentials. See
    lib/template/db_credentials.rb.
  MESSAGE
end
