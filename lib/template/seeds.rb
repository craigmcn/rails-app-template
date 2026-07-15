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

  create_file "db/seeds.rb", force: true do
    <<~RUBY
      # Roles
      admin_role = Role.find_or_create_by!(name: "admin")
      Role.find_or_create_by!(name: "moderator")
      member_role = Role.find_or_create_by!(name: "member")

      # Users
      #{user_block.strip}
    RUBY
  end
end
