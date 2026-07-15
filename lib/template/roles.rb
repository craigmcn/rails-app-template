# frozen_string_literal: true
# Applied by template.rb — always runs, after the auth module has created
# app/models/user.rb.

after_bundle do
  generate "model", "Role", "name:string:uniq"
  generate "model", "RoleAssignment", "user:references", "role:references"

  generate "migration", "AddUniqueIndexToRoleAssignments"
  migration_file = Dir.glob("db/migrate/*_add_unique_index_to_role_assignments.rb").max_by { |f| File.mtime(f) }
  if migration_file
    create_file migration_file, force: true do
      <<~RUBY
        class AddUniqueIndexToRoleAssignments < ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]
          def change
            add_index :role_assignments, [:user_id, :role_id], unique: true
          end
        end
      RUBY
    end
  end

  create_file "app/models/role.rb", force: true do
    <<~RUBY
      class Role < ApplicationRecord
        has_many :role_assignments, dependent: :destroy
        has_many :users, through: :role_assignments

        validates :name, presence: true, uniqueness: true
      end
    RUBY
  end

  create_file "app/models/role_assignment.rb", force: true do
    <<~RUBY
      class RoleAssignment < ApplicationRecord
        belongs_to :user
        belongs_to :role

        validates :role_id, uniqueness: {scope: :user_id}
      end
    RUBY
  end

  inject_into_class "app/models/user.rb", "User" do
    <<~RUBY.gsub(/^(?=.)/, "  ")
      has_many :role_assignments, dependent: :destroy
      has_many :roles, through: :role_assignments

      after_create :assign_default_role

    RUBY
  end

  inject_into_file "app/models/user.rb", before: /^end\n/ do
    <<~RUBY.gsub(/^(?=.)/, "  ")

      def admin?
        roles.exists?(name: "admin")
      end

      def moderator?
        roles.exists?(name: "moderator")
      end

      def member?
        !admin? && !moderator?
      end

      def moderator_or_above?
        moderator? || admin?
      end

      def primary_role
        return "admin" if admin?
        return "moderator" if moderator?

        "member"
      end

      private

      def assign_default_role
        member_role = Role.find_by(name: "member")
        roles << member_role if member_role
      end
    RUBY
  end
end
