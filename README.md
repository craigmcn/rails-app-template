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

| Flag | Values | Default |
|---|---|---|
| `--database` | any value `rails new --database` accepts (`sqlite3`, `postgresql`, `mysql`, `trilogy`, `mariadb-mysql`, `mariadb-trilogy`, ...) | `postgresql` |
| `--css` | any value `rails new --css` accepts (`tailwind`, `bootstrap`, `bulma`, `postcss`, `sass`, ...) | `bootstrap` |
| `--javascript` | any value `rails new --javascript` accepts (`importmap`, `bun`, `webpack`, `esbuild`, `rollup`, ...) | `esbuild` |
| `--auth` | `clearance`, `devise` | `clearance` |
| `--test` | `minitest`, `rspec` | `minitest` |
| `--skip-admin` | — | admin namespace included |

`--database`, `--css`, and `--javascript` are passed straight through to `rails new` unfiltered, so any value a given Rails version supports for those flags works here too — this tool doesn't hardcode or restrict the list.

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

See the file comments in `lib/template/` for what each piece does.
