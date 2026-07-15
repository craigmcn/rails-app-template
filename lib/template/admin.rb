# frozen_string_literal: true
# Applied by template.rb unless --skip-admin was passed.

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
        before_action :require_admin
        before_action :set_user, only: [:edit, :update]

        def index
          @users = User.all.order(:email)
        end

        def edit
        end

        def update
          role_names = Array(params.dig(:user, :role_names)).reject(&:blank?)
          @user.roles = Role.where(name: role_names)

          if @user.save
            redirect_to admin_users_path, notice: "Roles updated for \#{@user.email}."
          else
            render :edit, status: :unprocessable_entity
          end
        end

        private

        def set_user
          @user = User.find(params[:id])
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
end
