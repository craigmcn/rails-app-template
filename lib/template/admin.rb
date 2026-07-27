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
          role_names = Array(params.dig(:user, :role_names)).reject(&:blank?)

          if @user.admin? && !role_names.include?("admin") && last_admin?(@user)
            return redirect_to admin_users_path, alert: "Can't remove the last admin's admin role."
          end

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
end
