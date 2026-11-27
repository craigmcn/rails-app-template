# frozen_string_literal: true
# MySQL credentials go in the gitignored .env, and database.yml falls back to
# Rails' root/no password, so nothing secret is committed and Rails' generated
# CI (root, no password) still connects. Needs port.rb's .env; before db_create.

DATABASE = ENV.fetch("SCAFFOLD_DATABASE", "postgresql")

if DATABASE.match?(/mysql|trilogy/)
  db_username = ENV.fetch("SCAFFOLD_DB_USERNAME", "root")
  db_password = ENV.fetch("SCAFFOLD_DB_PASSWORD", "")

  # to_json keeps YAML-significant characters (": ", " #") in a value quoted.
  # presence, so a blank `DB_USERNAME=` left in .env means root, not "".
  username_line = '  username: <%= (ENV["DB_USERNAME"].presence || "root").to_json %>'
  password_line = '  password: <%= ENV["DB_PASSWORD"]&.to_json %>'
  gsub_file("config/database.yml", /^  username: root$/) { username_line }
  gsub_file("config/database.yml", /^  password:\s*$/) { password_line }

  # Rails hardcodes any MySQL socket on this machine, which overrides CI's host
  # (trilogy) or replaces the host line (mysql2). Connect over TCP, as a
  # socket-less scaffold does, with DB_SOCKET as an opt-in for socket-only servers.
  host_line = '  host: <%= ENV.fetch("DB_HOST") { "127.0.0.1" } %>'
  socket_line = '  socket: <%= ENV["DB_SOCKET"] %>'
  gsub_file("config/database.yml", %r{^ +socket: /.*\n}) { "" }
  gsub_file("config/database.yml", /^#{Regexp.escape(host_line)}\n/) { "" }
  gsub_file("config/database.yml", /^#{Regexp.escape(password_line)}\n/) { "#{password_line}\n#{host_line}\n#{socket_line}\n" }

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

    # Set only if your MySQL server has TCP turned off. --database=mysql
    # (mysql2) also needs DB_HOST=localhost before it will use the socket.
    # DB_SOCKET=/tmp/mysql.sock
  ENV

  # Rails writes these lines together in default:, so one check covers them.
  verified_inject "config/database.yml", "#{username_line}\n#{password_line}\n#{host_line}\n#{socket_line}\n", <<~MESSAGE
    Couldn't confirm config/database.yml reads its MySQL connection from
    DB_USERNAME/DB_PASSWORD/DB_HOST/DB_SOCKET (Rails' `username: root` /
    `password:` lines weren't found, so its wording may have changed).
    db:create will likely fail against a server that needs other credentials,
    and a socket path from this machine may be hardcoded. See
    lib/template/db_credentials.rb.
  MESSAGE
  if File.read("config/database.yml").match?(%r{^ +socket: /})
    note_for_end "config/database.yml still hardcodes a MySQL socket path from this machine, so the app's CI and other machines can't connect. Replace it with `socket: <%= ENV[\"DB_SOCKET\"] %>`.", :warnings
  end
end
