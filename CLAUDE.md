# rails-app-template

A reusable Rails application template (`rails new -m template.rb`) plus a CLI wrapper (`bin/new-rails-app`) for scaffolding new Rails apps with Pundit + roles-based authorization and a choice of Clearance/Devise auth baked in. See README.md for usage.

## Completed (2026-07-15)

- Repo scaffolded and committed to `main` (bc4b6d0) — not yet pushed to GitHub, not yet added to `~/.claude/active_projects.md`
- `bin/new-rails-app`: OptionParser CLI that execs `rails new` with `--database`/`--css`/`--javascript` passed straight through (full native option sets, no curation) plus `--auth`/`--test`/`--skip-admin` handled via `SCAFFOLD_*` env vars
- `template.rb` + `lib/template/*.rb`: applies, in order, `db:create` → Pundit wiring → auth (Clearance default / Devise) → roles/role_assignments system → admin namespace → CSS-specific view styling (bootstrap/tailwind/minimal fallback) → test framework (Minitest default / RSpec) → CI/tooling gems → generic seeds → `db:prepare` (migrate + seed) → generated `CLAUDE.md`
- Verified end-to-end by actually scaffolding apps (via `mise exec ruby@4.0.5`): SQLite+importmap baseline, Devise+Tailwind, and (separately, after the `db_create.rb`/`db.rb` fix below) the default `postgresql` baseline — all migrate and seed cleanly; the SQLite/Devise runs were also checked booting and gating `/admin` (admin → 200, member → 403, unauthenticated → redirect/block)

## Key decisions

- **Rails' own generator flags, not a bespoke option system** — `--css`/`--javascript`/`--database` are passed through unfiltered to `rails new` rather than curated, so the tool stays current as Rails adds/changes bundler or DB options automatically. Only `--auth` and `--test` are invented flags, since Rails has no native equivalent.
- **Baseline mirrors production apps, not designed from scratch** — the default stack (Postgres, Clearance, Pundit, esbuild+Sass+Bootstrap, Minitest+Capybara, roles table) was extracted from `~/Web/community_bookshelf`, `bookshelf-islands`, and `bookshelf-api`, which had already hand-built this exact pattern independently three times.
- **Trust Rails 8 defaults, don't reimplement them** — dropped a planned `procfile.rb` module (Rails' `--css`/`--javascript` generators already wire up `Procfile.dev`/`bin/dev` correctly) and a planned `ci.rb` CI-workflow generator (Rails 8 already generates `.github/workflows/ci.yml` with Brakeman/rubocop/tests, and already adds brakeman/bundler-audit/rubocop-rails-omakase/capybara/selenium-webdriver to the Gemfile). `ci.rb` now only adds `dotenv-rails`/`letter_opener`, which aren't Rails defaults.
- **`.yarnrc.yml` with `nodeLinker: node-modules` written synchronously, not in `after_bundle`** — Yarn 4's default PnP linker broke Bootstrap's Sass `@import` resolution; the file must exist on disk *before* Rails' own `--css`/`--javascript` setup runs any `yarn` command, so it's a plain top-level `create_file` in `template.rb`, not deferred.
- **`--skip-admin` only skips the `/admin` namespace UI**, not the underlying roles data model — roles stay useful for Pundit policies even without an admin UI.
- **Devise views get hand-styled per CSS framework** (bootstrap/tailwind), matching Clearance's treatment; other `--css` values (bulma/postcss/sass/none) fall back to plain unstyled-but-functional markup rather than guessing at framework-specific classes.
- **`db:create` runs as its own first step (`db_create.rb`), separate from the final `db:prepare` (`db.rb`)** — Clearance's and Devise's install generators query the database directly while generating (e.g. Clearance's `users_table_exists?`), which crashes the whole `rails new` process with an uncaught exception if the database doesn't exist yet. `db:create` has to happen before those generators run, not just before the final migrate/seed step. Discovered because only SQLite combinations (where the DB file just gets created on first access) had been tested end-to-end — the default `postgresql` path hit this immediately.

## Next / open

- Not pushed to GitHub yet; not added to `~/.claude/active_projects.md`'s repo table or dev-server-port table (deferred at user's request — "leave for later")
- Three of the many `--css`/`--javascript`/`--database` combinations have been end-to-end verified (SQLite+importmap+bootstrap+clearance, SQLite+importmap+tailwind+devise, and postgresql+esbuild+bootstrap+clearance). Untested: `--test=rspec` path, MySQL/trilogy/mariadb databases (which likely need the same "create before generators query it" treatment as postgresql — worth confirming), bulma/postcss/sass CSS fallback, bun/webpack/rollup JS bundlers, `--skip-admin`
- No automated test suite for the template/CLI itself (e.g. a script that scaffolds a matrix of option combinations in CI) — currently verified by hand
