# frozen_string_literal: true
# Applied by template.rb — always runs, last. Overwrites Rails' default
# README.md with an app-specific quickstart (setup, port, seeded users,
# troubleshooting) and writes CLAUDE.md documenting the deeper architecture,
# so neither a human nor a CLAUDE.md-reading assistant has to reverse-engineer
# the chosen stack from the Gemfile.

after_bundle do
  auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")
  test = ENV.fetch("SCAFFOLD_TEST", "minitest")
  css = ENV.fetch("SCAFFOLD_CSS", "bootstrap")
  javascript = ENV.fetch("SCAFFOLD_JAVASCRIPT", "esbuild")
  port = ENV.fetch("SCAFFOLD_PORT", "3000")
  bullet = ENV.fetch("SCAFFOLD_BULLET", "true") == "true"
  active_storage = ENV.fetch("SCAFFOLD_ACTIVE_STORAGE", "false") == "true"
  action_text = ENV.fetch("SCAFFOLD_ACTION_TEXT", "false") == "true"
  rack_attack = ENV.fetch("SCAFFOLD_RACK_ATTACK", "true") == "true"
  system_test_driver = ENV.fetch("SCAFFOLD_SYSTEM_TEST_DRIVER", "selenium")
  pagy = ENV.fetch("SCAFFOLD_PAGY", "true") == "true"
  annotate = ENV.fetch("SCAFFOLD_ANNOTATE", "true") == "true"
  app_dir = File.basename(destination_root)
  app_title = app_dir.split(/[-_]/).map(&:capitalize).join(" ")

  create_file "README.md", force: true do
    <<~MARKDOWN
      # #{app_title}

      Scaffolded with [rails-app-template](https://github.com/craigmcn/rails-app-template) — Rails #{Rails::VERSION::STRING}, #{ENV.fetch("SCAFFOLD_DATABASE", "postgresql")}, #{css} + #{javascript}, #{auth == "devise" ? "Devise" : "Clearance"} auth, #{test == "rspec" ? "RSpec" : "Minitest"} tests. See `CLAUDE.md` for the full architecture (authorization, roles, services convention).

      ## Setup

      The template's last scaffolding step ran `bin/rails db:prepare`
      (create, migrate, seed). If that succeeded:

      ```sh
      bin/dev
      ```

      ...starts the app at http://localhost:#{port} by default. Set `PORT` in
      `.env` (gitignored — copy from the committed `.env.sample`) to use a
      different port on this machine.

      If `db:prepare` failed during scaffolding (see Troubleshooting below),
      finish that step by hand once the database is reachable, then run
      `bin/dev` as above:

      ```sh
      bin/rails db:prepare
      ```

      ## Seeded users

      In development/test only, `bin/rails db:seed` creates an
      `admin@example.com` (admin role) and a `member@example.com` (member
      role) user, both with the password `correct-horse-battery`.
      This is a well-known, publicly documented password — the guard exists
      so a production `db:seed`/`db:prepare` run can never create these
      accounts. Remove or change them before any real users sign up.

      ## Troubleshooting

      **`FATAL: database "..." does not exist` (or similar, right after scaffolding)**

      `bin/rails db:prepare` couldn't reach the database server during
      scaffolding — the rest of the app was still scaffolded successfully.
      Start/fix the database server, then run `bin/rails db:prepare` by hand.

      | Symptom | Cause | Fix |
      |---|---|---|
      | `connection refused` / `could not connect to server` | Database server isn't running | Start it (e.g. `brew services start postgresql@16` on macOS) |
      | `FATAL: role "..." does not exist` | Postgres superuser/role doesn't match your OS user | Create a matching role: `createuser -s $(whoami)`, or set `PGUSER`/`username:` in `config/database.yml` |
      | `FATAL: password authentication failed` | `pg_hba.conf` requires a password but none is set | Set `PGPASSWORD`/`password:` in `config/database.yml`, or switch the local auth method to `trust`/`peer` |
      | Works for `sqlite3` but not `postgresql`/`mysql` | Only the SQLite path auto-creates a file; server-based databases need the server running first | Start the relevant server, then re-run `bin/rails db:prepare` |
    MARKDOWN
  end

  create_file "CLAUDE.md", force: true do
    <<~MARKDOWN
      # #{app_title}

      Scaffolded with [rails-app-template](https://github.com/craigmcn/rails-app-template).

      ## Tech Stack

      - **Rails** #{Rails::VERSION::STRING}
      - **Database**: #{ENV.fetch("SCAFFOLD_DATABASE", "postgresql")}
      - **Authentication**: #{auth == "devise" ? "Devise" : "Clearance"}
      - **Authorization**: Pundit (policy classes) + a `roles`/`role_assignments` table (`admin` / `moderator` / `member`)
      - **CSS**: #{css}
      - **JavaScript**: #{javascript}
      - **Testing**: #{test == "rspec" ? "RSpec + Capybara" : "Minitest + Capybara"} (system tests via #{system_test_driver == "cuprite" ? "Cuprite" : "Selenium"})
      #{bullet ? "- **N+1 detection**: Bullet (development only)" : ""}
      #{pagy ? "- **Pagination**: pagy" : ""}
      #{annotate ? "- **Schema annotations**: annotaterb (`bundle exec annotaterb models`)" : ""}
      #{active_storage ? "- **File uploads**: Active Storage" : ""}
      #{action_text ? "- **Rich text**: Action Text" : ""}
      #{rack_attack ? "- **Request throttling**: Rack::Attack (`config/initializers/rack_attack.rb`)" : ""}

      ## Setup

      The database was already created, migrated, and seeded as the last
      step of scaffolding. To start the app:

      ```sh
      bin/dev             # start the dev server (+ CSS/JS watchers if applicable)
      ```

      If `db:prepare` failed during scaffolding (e.g. the database server
      wasn't running yet), finish that step by hand once it's reachable:

      ```sh
      bin/rails db:prepare
      ```

      ## Port

      The dev server binds to port #{port} by default. To use a different port
      on this machine, set `PORT` in `.env` (gitignored — copy from
      `.env.sample`, which is the committed template). `bin/dev` and the
      development mailer's `default_url_options` both read it from there.

      ## Authorization

      - `ApplicationController` includes `Pundit::Authorization`; `Pundit::NotAuthorizedError` is rescued with a flash + redirect.
      - One policy class per model lives in `app/policies/`, all defaulting to `false` — add explicit `?` methods to allow actions.
      - `User#admin?` / `#moderator?` / `#member?` / `#moderator_or_above?` / `#primary_role` come from the roles system in `app/models/user.rb`, `app/models/role.rb`, `app/models/role_assignment.rb`.
      - New users get the `member` role automatically (`User#assign_default_role`).
      - `/admin` is namespaced behind `Admin::BaseController#require_moderator_or_above`; `Admin::UsersController` (admin-only) manages role assignments.

      ## Services

      Business/orchestration logic lives in `app/services/`, one flat layer
      of `ApplicationService` subclasses (no separate "actions" layer) —
      controllers call services directly, and services may call each other.
      Authorization stays in the controller (Pundit policies); a service's
      own argument shape is validated via a `dry-schema` `SCHEMA` constant.

      ```sh
      bin/rails generate service Authentication::CreateSession
      ```

      generates `app/services/authentication/create_session.rb` plus a
      matching #{test == "rspec" ? "spec/services/.../..._spec.rb" : "test/services/.../..._test.rb"}.
      Nested service calls can be stubbed in tests via the `deps` hash
      (`SomeService.call(args, "Other::Service" => ->(args, _deps) { ... })`).

      ## Seeded users

      In development/test only (`Rails.env.local?`), `bin/rails db:seed` creates an `admin@example.com` (admin role) and a `member@example.com` (member role) user, both with the password `#{auth == "devise" ? "correct-horse-battery" : "User::DEFAULT_PASSWORD (\"correct-horse-battery\")"}`. This is a well-known, publicly documented password — the guard exists so a production `db:seed`/`db:prepare` run can never create these accounts. Remove or change them before any real users sign up.
      #{auth == "devise" ? <<~DEVISE_MAILER : ""}

        ## Before deploying to production

        `config/environments/production.rb` reads the mailer's host from `ENV.fetch("HOST", "example.com")`. Set `HOST` to the app's real production domain via whatever env var mechanism the production platform uses (Heroku config vars, Kamal secrets, systemd environment, etc.) — **not** `.env`/`.env.sample`, which are dev-only and never loaded in production. Until `HOST` is set there, confirmation/password-reset emails will link to `example.com`.
      DEVISE_MAILER
    MARKDOWN
  end

  # rails new runs in the directory it was invoked from, not inside the new
  # app dir — the caller's shell is still in the parent, so bin/dev needs a
  # cd first even though the generator process itself has already chdir'd.
  if @db_prepare_succeeded
    say <<~MESSAGE, :green
      #{app_title} is ready.

          cd #{app_dir}
          bin/dev

      ...starts the app at http://localhost:#{port} (set PORT in .env to use a
      different port on this machine — see .env.sample).
    MESSAGE
  else
    say <<~MESSAGE, :yellow
      #{app_title} was scaffolded, but db:prepare failed above — fix that
      first (see the red message above and README.md > Troubleshooting),
      then run:

          cd #{app_dir}
          bin/dev

      ...to start the app at http://localhost:#{port} (set PORT in .env to use
      a different port on this machine — see .env.sample).
    MESSAGE
  end

  if auth == "devise"
    say <<~MESSAGE, :yellow
      Before deploying to production: set the HOST environment variable to
      the app's real production domain, via whatever mechanism your
      production platform uses for env vars (not .env/.env.sample — those
      are dev-only and never loaded in production). Until HOST is set
      there, config/environments/production.rb falls back to "example.com"
      for confirmation/password-reset email links.
    MESSAGE

    # Deferred from devise:install above so it's the last thing printed,
    # not buried under every subsequent generator's output.
    if @devise_install_readme
      say "\n#{@devise_install_readme}", :yellow
    end
  end
end
