# frozen_string_literal: true
# Applied by template.rb — always runs, last. Documents the stack that was
# actually chosen so a CLAUDE.md-reading assistant (or a human) doesn't have
# to reverse-engineer it from the Gemfile.

after_bundle do
  auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")
  test = ENV.fetch("SCAFFOLD_TEST", "minitest")
  css = ENV.fetch("SCAFFOLD_CSS", "bootstrap")
  javascript = ENV.fetch("SCAFFOLD_JAVASCRIPT", "esbuild")
  app_title = File.basename(destination_root).split(/[-_]/).map(&:capitalize).join(" ")

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
      - **Testing**: #{test == "rspec" ? "RSpec + Capybara" : "Minitest + Capybara"}

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

      ## Authorization

      - `ApplicationController` includes `Pundit::Authorization`; `Pundit::NotAuthorizedError` is rescued with a flash + redirect.
      - One policy class per model lives in `app/policies/`, all defaulting to `false` — add explicit `?` methods to allow actions.
      - `User#admin?` / `#moderator?` / `#member?` / `#moderator_or_above?` / `#primary_role` come from the roles system in `app/models/user.rb`, `app/models/role.rb`, `app/models/role_assignment.rb`.
      - New users get the `member` role automatically (`User#assign_default_role`).
      - `/admin` is namespaced behind `Admin::BaseController#require_moderator_or_above`; `Admin::UsersController` (admin-only) manages role assignments.

      ## Seeded users

      `bin/rails db:seed` creates an `admin@example.com` (admin role) and a `member@example.com` (member role) user, both with the password `#{auth == "devise" ? "correct-horse-battery" : "User::DEFAULT_PASSWORD (\"correct-horse-battery\")"}`.
    MARKDOWN
  end
end
