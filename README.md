# rails-app-template

A reusable [Rails application template](https://guides.rubyonrails.org/rails_application_templates.html) for scaffolding new Rails apps with an opinionated authorization baseline on top of Rails' own generator options.

Every new app gets, regardless of flags:

- **Pundit** for authorization (`ApplicationController` wired up, `ApplicationPolicy` base class)
- A **roles** system (`roles` / `role_assignments` tables, `User#admin?` / `#moderator?` / `#member?` / `#moderator_or_above?`, default `member` role on signup)
- An **admin namespace** (`/admin`, gated to moderators/admins; user role management gated to admins) — opt out with `--skip-admin`
- Login, sign up, and reset-password views styled to match the chosen CSS framework
- A generated `CLAUDE.md` documenting the chosen stack
- Bullet, pagy, annotaterb, and Rack::Attack, all on by default — opt out per-app with `--no-bullet`/`--no-pagy`/`--no-annotate`/`--no-rack-attack`
- Active Storage and Action Text, off by default — opt in with `--active-storage`/`--action-text`

## Usage

```sh
bin/new-rails-app [my_app] [options]
```

Any option left out (including the app name) is prompted for interactively — select lists for the closed choices (`--auth`, `--test`, `--css`, etc.), yes/no for the toggles, free text for `my_app`/`--port`, and a summary + confirmation before `rails new` actually runs. Passing a flag on the command line skips its prompt, so scripted/partial invocations work the same as before. Pass `--no-interactive` to skip prompting entirely (for CI/non-TTY use) — the app name is still required, but any option left unspecified falls back to its default from the table below instead of being prompted for.

`rails new` creates the app relative to your current working directory, not relative to this repo — `bin/new-rails-app` never changes directories. Run it from wherever you want `my_app/` to land, e.g. from this repo's parent directory to create `my_app` as a sibling of `rails-app-template`:

```sh
cd ..
rails-app-template/bin/new-rails-app my_app [options]
```

| Flag | Values | Default |
|---|---|---|
| `--database` | any value `rails new --database` accepts (`sqlite3`, `postgresql`, `mysql`, `trilogy`, `mariadb-mysql`, `mariadb-trilogy`, ...) | `postgresql` |
| `--db-username` / `--db-password` | any string — MySQL/trilogy only | `root` / blank |
| `--css` | any value `rails new --css` accepts (`tailwind`, `bootstrap`, `bulma`, `postcss`, `sass`, ...) | `bootstrap` |
| `--javascript` | any value `rails new --javascript` accepts (`importmap`, `bun`, `webpack`, `esbuild`, `rollup`, ...) | `esbuild` |
| `--auth` | `clearance`, `devise` | `clearance` |
| `--test` | `minitest`, `rspec` | `minitest` |
| `--skip-admin` | — | admin namespace included |
| `--bullet` / `--no-bullet` | — | Bullet (N+1 query detector) included |
| `--port` | any integer | `3000` |
| `--active-storage` / `--no-active-storage` | — | Active Storage omitted |
| `--action-text` / `--no-action-text` | — (implies `--active-storage`) | Action Text omitted |
| `--rack-attack` / `--no-rack-attack` | — | Rack::Attack included |
| `--system-test-driver` | `selenium`, `cuprite` | `selenium` |
| `--pagy` / `--no-pagy` | — | pagy included |
| `--annotate` / `--no-annotate` | — | annotaterb included |
| `--no-interactive` | — | prompts enabled |

`--database`, `--css`, and `--javascript` are passed straight through to `rails new` unfiltered, so any value a given Rails version supports for those flags works here too — this tool doesn't hardcode or restrict the list. The interactive prompts for these three only offer a curated subset for convenience; pass the flag directly for anything outside that list.

The interactive mode uses [tty-prompt](https://github.com/piotrmurach/tty-prompt), pulled in via `bundler/inline` on first run — no separate `gem install` step needed, and nothing is added to this repo's own dependencies.

If you used `--skip-admin` and later want CRUD UI for a given model, you don't need to regenerate the app: `rails generate scaffold_controller ModelName field:type field:type ...` (matching the model's actual fields) adds a controller and views for an existing model without touching the model or its migration.

Auth/admin/CSS view styling is fully hand-tuned for the default combination (`bootstrap` + `clearance`) and for `tailwind` + `devise`; other `--css` values (`bulma`, `postcss`, `sass`, none) fall back to plain, unstyled-but-functional markup rather than framework-specific classes.

### Examples

```sh
# fully interactive — prompts for every option not given below
bin/new-rails-app my_app

# SQLite + importmap, no build step, RSpec instead of Minitest;
# still prompts for whatever's left out (auth, css, skip-admin, bullet, port)
bin/new-rails-app my_app --database=sqlite3 --javascript=importmap --test=rspec

# Devise auth, Tailwind CSS — same partial-prompt behavior
bin/new-rails-app my_app --auth=devise --css=tailwind

# non-interactive default baseline (CI/scripting) — matches
# community_bookshelf/bookshelf-islands/bookshelf-api; --no-interactive
# skips all prompts and applies the defaults table below to anything
# left unspecified, so this is equivalent to just:
#   bin/new-rails-app my_app --no-interactive
bin/new-rails-app my_app --no-interactive --database=postgresql --css=bootstrap \
  --javascript=esbuild --auth=clearance --test=minitest
```

## How it works

`bin/new-rails-app` prompts (via [tty-prompt](https://github.com/piotrmurach/tty-prompt)) for any option not passed as a flag, then sets `SCAFFOLD_*` environment variables (one per option in the table above) and execs `rails new` with the matching native flags plus `-m template.rb`. `template.rb` applies the files under `lib/template/` in order — each one adds gems immediately and defers any generator/model-editing work that needs those gems into an `after_bundle` block, since bundling happens after the template body runs.

As its last step, the template runs `bin/rails db:prepare` (creates, migrates, and seeds the database), so a successful `bin/new-rails-app my_app` leaves you with an app that's immediately ready for `bin/dev` — no manual database setup step required.

See the file comments in `lib/template/` for what each piece does.

## Prerequisites

- A running database server matching your `--database` choice (default `postgresql`). On macOS with Homebrew: `brew services start postgresql@16` (or whichever version you have installed).
- No `username`/`password` is set in the generated `config/database.yml` for Postgres, so it connects as your local OS user over the default socket — this matches Homebrew's default (trust-auth) Postgres setup with no extra configuration.
- For `--database=mysql`/`trilogy`, Rails' own default `config/database.yml` hardcodes `username: root` with a blank password and no local-OS-user fallback — if your MySQL server's root user needs a real password (or you'd rather connect as a different user), pass `--db-username`/`--db-password` (or answer the matching prompts) so `db:create` doesn't fail immediately.

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
| `Access denied for user 'root'@'localhost'` (MySQL/trilogy) | The server's root user needs a password, or a different user, that `--db-username`/`--db-password` weren't given for | Re-run with the right `--db-username`/`--db-password` (or answer the prompts), or edit `config/database.yml` by hand and re-run `bin/rails db:create` |
