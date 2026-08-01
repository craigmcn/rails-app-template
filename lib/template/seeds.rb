# frozen_string_literal: true
# Applied by template.rb unless --skip-admin was passed.

after_bundle do
  auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")

  user_block =
    if auth == "devise"
      <<~RUBY
        User.find_or_create_by!(email: "admin@example.com") do |u|
          u.password = "correct-horse-battery"
          u.password_confirmation = "correct-horse-battery"
        end.tap { |u| u.roles = [admin_role] }

        User.find_or_create_by!(email: "member@example.com") do |u|
          u.password = "correct-horse-battery"
          u.password_confirmation = "correct-horse-battery"
        end.tap { |u| u.roles = [member_role] }
      RUBY
    else
      <<~RUBY
        User.find_or_create_by!(email: "admin@example.com") { |u| u.password = User::DEFAULT_PASSWORD }
                            .tap { |u| u.roles = [admin_role] }

        User.find_or_create_by!(email: "member@example.com") { |u| u.password = User::DEFAULT_PASSWORD }
                            .tap { |u| u.roles = [member_role] }
      RUBY
    end

  indented_user_block = user_block.strip.each_line.map { |line| line == "\n" ? line : "  #{line}" }.join

  create_file "db/seeds.rb", force: true do
    <<~RUBY
      # Roles
      admin_role = Role.find_or_create_by!(name: "admin")
      Role.find_or_create_by!(name: "moderator")
      member_role = Role.find_or_create_by!(name: "member")

      # Users — local (development/test) only. A production db:seed/db:prepare
      # run (e.g. a first-deploy release phase) must never create these: the
      # password is a well-known, publicly documented default.
      #
      # Rails.env.local? already excludes production today, but the
      # `&& !Rails.env.production?` below is intentionally redundant: it's
      # a second, independent check so that if this guard is ever loosened
      # (e.g. broadened to include a future custom environment) by a later
      # edit, account creation with a known password still can't reach a
      # production database on its own.
      if Rails.env.local? && !Rails.env.production?
      #{indented_user_block}
      end
    RUBY
  end
end
