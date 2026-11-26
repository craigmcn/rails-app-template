# frozen_string_literal: true
# Applied by template.rb — after port.rb (which creates .env/.env.sample) and
# before db_create.rb. Only touches mysql/trilogy apps: Rails' database.yml for
# those hardcodes root with a blank password, with no OS-user fallback like
# Postgres has. The chosen credentials go in the gitignored .env, and
# database.yml reads them from ENV with Rails' own defaults as the fallback, so
# the password isn't committed and Rails' generated CI (root, no password) works.

DATABASE = ENV.fetch("SCAFFOLD_DATABASE", "postgresql")

if DATABASE.match?(/mysql|trilogy/)
  db_username = ENV.fetch("SCAFFOLD_DB_USERNAME", "root")
  db_password = ENV.fetch("SCAFFOLD_DB_PASSWORD", "")

  # to_json keeps YAML-significant characters (": ", " #") in a value quoted.
  username_line = '  username: <%= ENV.fetch("DB_USERNAME", "root").to_json %>'
  password_line = '  password: <%= ENV["DB_PASSWORD"]&.to_json %>'
  gsub_file("config/database.yml", /^  username: root$/) { username_line }
  gsub_file("config/database.yml", /^  password:\s*$/) { password_line }

  # Double quotes with these escapes read back literally in both dotenv and
  # bin/dev's `. ./.env`; single quotes can't hold a "'" for dotenv.
  dotenv_quote = ->(value) { "\"#{value.gsub(/[\\"$`]/) { |char| "\\#{char}" }}\"" }
  credentials = { "DB_USERNAME" => (db_username unless db_username == "root"),
                  "DB_PASSWORD" => (db_password unless db_password.empty?) }.compact
  unless credentials.empty?
    append_to_file ".env", credentials.map { |key, value| "#{key}=#{dotenv_quote.call(value)}\n" }.join
  end

  append_to_file ".env.sample", <<~ENV

    # MySQL credentials for development and test. Unset, config/database.yml
    # uses root with no password, which is what the generated CI's MySQL has.
    # DB_USERNAME=root
    # DB_PASSWORD=
  ENV

  # Rails writes the two lines together, so one check covers both.
  verified_inject "config/database.yml", "#{username_line}\n#{password_line}\n", <<~MESSAGE
    Couldn't confirm config/database.yml reads its MySQL credentials from
    DB_USERNAME/DB_PASSWORD (Rails' `username: root` / `password:` lines
    weren't found, so its wording may have changed). db:create will likely
    fail against a server that needs other credentials. See
    lib/template/db_credentials.rb.
  MESSAGE
end
