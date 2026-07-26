# rails-app-template

A reusable [Rails application template](https://guides.rubyonrails.org/rails_application_templates.html) for scaffolding new Rails apps with an opinionated authorization baseline on top of Rails' own generator options.

Every new app gets, regardless of flags:

- **Pundit** for authorization (`ApplicationController` wired up, `ApplicationPolicy` base class)
- A **roles** system (`roles` / `role_assignments` tables, `User#admin?` / `#moderator?` / `#member?` / `#moderator_or_above?`, default `member` role on signup)
- An **admin namespace** (`/admin`, gated to moderators/admins; user role management gated to admins) — opt out with `--skip-admin`
- Login, sign up, and reset-password views styled to match the chosen CSS framework
- A generated `CLAUDE.md` documenting the chosen stack

## Usage

```sh
bin/new-rails-app my_app [options]
```

`rails new` creates the app relative to your current working directory, not relative to this repo — `bin/new-rails-app` never changes directories. Run it from wherever you want `my_app/` to land, e.g. from this repo's parent directory to create `my_app` as a sibling of `rails-app-template`:

```sh
cd ..
rails-app-template/bin/new-rails-app my_app [options]
```

| Flag | Values | Default |
|---|---|---|
| `--database` | any value `rails new --database` accepts (`sqlite3`, `postgresql`, `mysql`, `trilogy`, `mariadb-mysql`, `mariadb-trilogy`, ...) | `postgresql` |
| `--css` | any value `rails new --css` accepts (`tailwind`, `bootstrap`, `bulma`, `postcss`, `sass`, ...) | `bootstrap` |
| `--javascript` | any value `rails new --javascript` accepts (`importmap`, `bun`, `webpack`, `esbuild`, `rollup`, ...) | `esbuild` |
| `--auth` | `clearance`, `devise` | `clearance` |
| `--test` | `minitest`, `rspec` | `minitest` |
| `--skip-admin` | — | admin namespace included |

`--database`, `--css`, and `--javascript` are passed straight through to `rails new` unfiltered, so any value a given Rails version supports for those flags works here too — this tool doesn't hardcode or restrict the list.

If you used `--skip-admin` and later want CRUD UI for a given model, you don't need to regenerate the app: `rails generate scaffold_controller ModelName field:type field:type ...` (matching the model's actual fields) adds a controller and views for an existing model without touching the model or its migration.

Auth/admin/CSS view styling is fully hand-tuned for the default combination (`bootstrap` + `clearance`) and for `tailwind` + `devise`; other `--css` values (`bulma`, `postcss`, `sass`, none) fall back to plain, unstyled-but-functional markup rather than framework-specific classes.

### Examples

```sh
# default baseline — matches community_bookshelf/bookshelf-islands/bookshelf-api
bin/new-rails-app my_app

# SQLite + importmap, no build step, RSpec instead of Minitest
bin/new-rails-app my_app --database=sqlite3 --javascript=importmap --test=rspec

# Devise auth, Tailwind CSS
bin/new-rails-app my_app --auth=devise --css=tailwind
```

## How it works

`bin/new-rails-app` sets `SCAFFOLD_*` environment variables (the auth/test/css/javascript choices) and execs `rails new` with the matching native flags plus `-m template.rb`. `template.rb` applies the files under `lib/template/` in order — each one adds gems immediately and defers any generator/model-editing work that needs those gems into an `after_bundle` block, since bundling happens after the template body runs.

As its last step, the template runs `bin/rails db:prepare` (creates, migrates, and seeds the database), so a successful `bin/new-rails-app my_app` leaves you with an app that's immediately ready for `bin/dev` — no manual database setup step required.

See the file comments in `lib/template/` for what each piece does.

## Prerequisites

- A running database server matching your `--database` choice (default `postgresql`). On macOS with Homebrew: `brew services start postgresql@16` (or whichever version you have installed).
- No `username`/`password` is set in the generated `config/database.yml` for Postgres, so it connects as your local OS user over the default socket — this matches Homebrew's default (trust-auth) Postgres setup with no extra configuration.

## Troubleshooting

**`FATAL: database "my_app_development" does not exist` (or similar, right after scaffolding)**

The template's final step (`bin/rails db:prepare`) couldn't reach the database server — the rest of the app was still scaffolded successfully. Start/fix the database server, then finish setup by hand:

```sh
cd my_app
bin/rails db:prepare
```

Common causes:

| Symptom | Cause | Fix |
|---|---|---|
| `connection refused` / `could not connect to server` | Database server isn't running | `brew services start postgresql@16` (adjust version/db as needed) |
| `FATAL: role "..." does not exist` | Postgres superuser/role doesn't match your OS user | Create a matching role: `createuser -s $(whoami)`, or set `PGUSER`/`username:` in `config/database.yml` |
| `FATAL: password authentication failed` | `pg_hba.conf` requires a password but none is set | Set `PGPASSWORD`/`password:` in `config/database.yml`, or switch the local auth method to `trust`/`peer` |
| Works for `sqlite3` but not `postgresql`/`mysql` | Only the SQLite path auto-creates a file; server-based databases need the server running first | Start the relevant server before running `bin/new-rails-app` |
