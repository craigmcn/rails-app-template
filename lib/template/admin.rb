# frozen_string_literal: true
# Applied by template.rb unless --skip-admin was passed.

auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")
test = ENV.fetch("SCAFFOLD_TEST", "minitest")

# Clearance's global `before_action :require_login` (added in
# auth_clearance.rb) runs before Admin::BaseController's own gate, so an
# anonymous request never reaches it and gets redirected to sign in instead.
# Devise doesn't add an equivalent global filter, so anonymous requests do
# reach require_moderator_or_above, where current_user is nil and the
# response is a plain 403.
anonymous_status = auth == "devise" ? "forbidden" : "redirect"
anonymous_verb = auth == "devise" ? "forbids" : "redirects"

after_bundle do
  create_file "app/controllers/admin/base_controller.rb" do
    <<~RUBY
      class Admin::BaseController < ApplicationController
        before_action :require_moderator_or_above

        private

        def require_moderator_or_above
          render plain: "Forbidden", status: :forbidden unless current_user&.moderator_or_above?
        end

        def require_admin
          render plain: "Forbidden", status: :forbidden unless current_user&.admin?
        end
      end
    RUBY
  end

  create_file "app/controllers/admin/dashboard_controller.rb" do
    <<~RUBY
      class Admin::DashboardController < Admin::BaseController
        def index
        end
      end
    RUBY
  end

  create_file "app/controllers/admin/users_controller.rb" do
    <<~RUBY
      class Admin::UsersController < Admin::BaseController
        PER_PAGE = 50

        before_action :require_admin
        before_action :set_user, only: [ :edit, :update ]

        def index
          page = [ params[:page].to_i, 1 ].max
          @users = User.includes(:roles).order(:email).offset((page - 1) * PER_PAGE).limit(PER_PAGE)
          @page = page
          @total_pages = (User.count / PER_PAGE.to_f).ceil
        end

        def edit
        end

        def update
          role_names = user_params.fetch(:role_names, []).reject(&:blank?)
          demoting_admin = @user.admin? && !role_names.include?("admin")

          ActiveRecord::Base.transaction do
            # Locking the shared "admin" Role row (not @user's own row) is
            # what actually closes the race: two requests demoting two
            # *different* admins both need this same lock, so the second
            # one only proceeds after the first has committed, and its
            # last_admin? check then sees the up-to-date admin count.
            Role.lock.find_by(name: "admin") if demoting_admin

            if demoting_admin && last_admin?(@user)
              return redirect_to admin_users_path, alert: "Can't remove the last admin's admin role."
            end

            @user.roles = Role.where(name: role_names)

            if @user.save
              redirect_to admin_users_path, notice: "Roles updated for \#{@user.email}."
            else
              render :edit, status: :unprocessable_entity
            end
          end
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(role_names: [])
        end

        def last_admin?(user)
          User.joins(:roles).where(roles: { name: "admin" }).where.not(id: user.id).none?
        end
      end
    RUBY
  end

  create_file "app/views/admin/dashboard/index.html.erb" do
    <<~ERB
      <h1>Admin dashboard</h1>
      <p><%= link_to "Manage users", admin_users_path %></p>
    ERB
  end

  create_file "app/views/admin/users/index.html.erb" do
    <<~ERB
      <h1>Users</h1>
      <ul>
        <% @users.each do |user| %>
          <li><%= link_to user.email, edit_admin_user_path(user) %> (<%= user.primary_role %>)</li>
        <% end %>
      </ul>

      <% if @total_pages > 1 %>
        <nav>
          <% (1..@total_pages).each do |page_number| %>
            <% if page_number == @page %>
              <strong><%= page_number %></strong>
            <% else %>
              <%= link_to page_number, admin_users_path(page: page_number) %>
            <% end %>
          <% end %>
        </nav>
      <% end %>
    ERB
  end

  create_file "app/views/admin/users/edit.html.erb" do
    <<~ERB
      <h1><%= @user.email %></h1>

      <%= form_with model: @user, url: admin_user_path(@user), method: :patch do |f| %>
        <% Role.order(:name).each do |role| %>
          <label>
            <%= check_box_tag "user[role_names][]", role.name, @user.roles.include?(role) %>
            <%= role.name %>
          </label>
        <% end %>
        <%= f.submit "Update roles" %>
      <% end %>
    ERB
  end

  route <<~RUBY
    namespace :admin do
      root "dashboard#index"
      resources :users, only: [:index, :edit, :update]
    end
  RUBY

  # Small per-framework "how do I spell this" helpers so the sign-in/status
  # syntax lives in one place instead of being hand-duplicated at every call
  # site across the four generated test files below — the RSpec/Minitest
  # bodies otherwise differ only in these fragments, not in structure.
  rspec = test == "rspec"
  user_ref = lambda do |role|
    if rspec
      role == "member" ? "create(:user)" : "create(:user, :#{role})"
    else
      "users(:#{role})"
    end
  end
  sign_in_expr = ->(expr) { "sign_in_as(#{expr})" }
  sign_in_line = ->(role) { sign_in_expr.call(user_ref.call(role)) }
  assert_status_line = ->(status) { rspec ? "expect(response).to have_http_status(:#{status})" : "assert_response :#{status}" }
  assert_redirect_line = ->(path) { rspec ? "expect(response).to redirect_to(#{path})" : "assert_redirected_to #{path}" }

  if rspec
    create_file "spec/requests/admin/dashboard_spec.rb" do
      <<~RUBY
        require "rails_helper"

        RSpec.describe "Admin::Dashboard", type: :request do
          it "forbids a member" do
            #{sign_in_line.call("member")}
            get admin_root_path
            #{assert_status_line.call("forbidden")}
          end

          it "allows a moderator" do
            #{sign_in_line.call("moderator")}
            get admin_root_path
            #{assert_status_line.call("success")}
          end

          it "allows an admin" do
            #{sign_in_line.call("admin")}
            get admin_root_path
            #{assert_status_line.call("success")}
          end

          it "#{anonymous_verb} an anonymous request" do
            get admin_root_path
            #{assert_status_line.call(anonymous_status)}
          end
        end
      RUBY
    end

    create_file "spec/requests/admin/users_spec.rb" do
      <<~RUBY
        require "rails_helper"

        RSpec.describe "Admin::Users", type: :request do
          it "forbids a moderator from the users index" do
            #{sign_in_line.call("moderator")}
            get admin_users_path
            #{assert_status_line.call("forbidden")}
          end

          it "allows an admin to access the users index" do
            #{sign_in_line.call("admin")}
            get admin_users_path
            #{assert_status_line.call("success")}
          end

          it "persists a role assignment made by an admin" do
            #{sign_in_line.call("admin")}
            member = create(:user)
            create(:role, :moderator)

            patch admin_user_path(member), params: { user: { role_names: [ "moderator" ] } }

            #{assert_redirect_line.call("admin_users_path")}
            member.reload
            expect(member.moderator?).to be true
            expect(member.member?).to be false
          end

          it "cannot remove the last admin's admin role" do
            admin = #{user_ref.call("admin")}
            #{sign_in_expr.call("admin")}

            patch admin_user_path(admin), params: { user: { role_names: [ "member" ] } }

            #{assert_redirect_line.call("admin_users_path")}
            expect(admin.reload.admin?).to be true
          end
        end
      RUBY
    end
  else
    create_file "test/controllers/admin/dashboard_controller_test.rb" do
      <<~RUBY
        require "test_helper"

        class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
          test "forbids a member" do
            #{sign_in_line.call("member")}
            get admin_root_path
            #{assert_status_line.call("forbidden")}
          end

          test "allows a moderator" do
            #{sign_in_line.call("moderator")}
            get admin_root_path
            #{assert_status_line.call("success")}
          end

          test "allows an admin" do
            #{sign_in_line.call("admin")}
            get admin_root_path
            #{assert_status_line.call("success")}
          end

          test "#{anonymous_verb} an anonymous request" do
            get admin_root_path
            #{assert_status_line.call(anonymous_status)}
          end
        end
      RUBY
    end

    create_file "test/controllers/admin/users_controller_test.rb" do
      <<~RUBY
        require "test_helper"

        class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
          test "forbids a moderator from the users index" do
            #{sign_in_line.call("moderator")}
            get admin_users_path
            #{assert_status_line.call("forbidden")}
          end

          test "allows an admin to access the users index" do
            #{sign_in_line.call("admin")}
            get admin_users_path
            #{assert_status_line.call("success")}
          end

          test "persists a role assignment made by an admin" do
            #{sign_in_line.call("admin")}
            member = users(:member)

            patch admin_user_path(member), params: { user: { role_names: [ "moderator" ] } }

            #{assert_redirect_line.call("admin_users_path")}
            member.reload
            assert member.moderator?
            refute member.member?
          end

          test "cannot remove the last admin's admin role" do
            admin = #{user_ref.call("admin")}
            #{sign_in_expr.call("admin")}

            patch admin_user_path(admin), params: { user: { role_names: [ "member" ] } }

            #{assert_redirect_line.call("admin_users_path")}
            assert admin.reload.admin?
          end
        end
      RUBY
    end
  end
end
