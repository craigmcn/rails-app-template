# frozen_string_literal: true
# Applied by template.rb when --css=tailwind.

auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")

after_bundle do
  create_file "app/controllers/home_controller.rb", force: true do
    <<~RUBY
      class HomeController < ApplicationController
        skip_before_action :require_login, raise: false
        skip_before_action :authenticate_user!, raise: false

        def index
        end
      end
    RUBY
  end

  create_file "app/views/home/index.html.erb", force: true do
    <<~ERB
      <div class="text-center py-16">
        <h1 class="text-4xl font-bold tracking-tight">#{app_title}</h1>
        <p class="mt-4 text-lg text-gray-600">This app was scaffolded with rails-app-template.</p>
      </div>
    ERB
  end

  route 'root "home#index"'

  create_file "app/views/layouts/application.html.erb", force: true do
    sign_in_link, sign_out_button, sign_up_link, current_user_email, signed_in_check =
      if auth == "devise"
        [
          'link_to "Sign In", new_user_session_path, class: "text-sm font-medium text-gray-200 hover:text-white"',
          'button_to "Sign Out", destroy_user_session_path, method: :delete, class: "text-sm font-medium text-gray-200 hover:text-white bg-transparent border border-gray-500 rounded px-3 py-1"',
          'link_to "Sign Up", new_user_registration_path, class: "text-sm font-medium bg-indigo-600 hover:bg-indigo-500 text-white rounded px-3 py-1"',
          "current_user.email",
          "user_signed_in?"
        ]
      else
        [
          'link_to "Sign In", sign_in_path, class: "text-sm font-medium text-gray-200 hover:text-white"',
          'button_to "Sign Out", sign_out_path, method: :delete, class: "text-sm font-medium text-gray-200 hover:text-white bg-transparent border border-gray-500 rounded px-3 py-1"',
          'link_to "Sign Up", sign_up_path, class: "text-sm font-medium bg-indigo-600 hover:bg-indigo-500 text-white rounded px-3 py-1"',
          "current_user.email",
          "signed_in?"
        ]
      end

    <<~ERB
      <!DOCTYPE html>
      <html>
        <head>
          <title><%= content_for(:title) || "#{app_title}" %></title>
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <%= csrf_meta_tags %>
          <%= csp_meta_tag %>
          <%= yield :head %>
          <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
          <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
        </head>

        <body class="bg-white text-gray-900">
          <nav class="bg-gray-900">
            <div class="mx-auto max-w-5xl px-4 flex items-center justify-between h-14">
              <%= link_to "#{app_title}", root_path, class: "text-white font-semibold" %>

              <div class="flex items-center gap-4">
                <% if #{signed_in_check} %>
                  <span class="text-sm text-gray-300"><%= #{current_user_email} %></span>
                  <%= #{sign_out_button} %>
                <% else %>
                  <%= #{sign_in_link} %>
                  <%= #{sign_up_link} %>
                <% end %>
              </div>
            </div>
          </nav>

          <main class="mx-auto max-w-5xl px-4 mt-6">
            <% if notice.present? %>
              <div class="mb-4 rounded bg-green-50 text-green-800 px-4 py-3 text-sm"><%= notice %></div>
            <% end %>
            <% if alert.present? %>
              <div class="mb-4 rounded bg-red-50 text-red-800 px-4 py-3 text-sm"><%= alert %></div>
            <% end %>

            <%= yield %>
          </main>
        </body>
      </html>
    ERB
  end

  card_open = <<~ERB
    <div class="flex justify-center mt-12">
      <div class="w-full max-w-sm bg-white border border-gray-200 rounded-lg shadow-sm p-6">
  ERB
  card_close = "      </div>\n    </div>\n"

  if auth == "clearance"
    create_file "app/views/sessions/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Sign In" %>
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Sign In</h2>
            <%= render partial: "/sessions/form" %>
        #{card_close}
      ERB
    end

    create_file "app/views/sessions/_form.html.erb", force: true do
      <<~ERB
        <%= form_for :session, url: session_path do |form| %>
          <div class="mb-4">
            <%= form.label :email, class: "block text-sm font-medium mb-1" %>
            <%= form.email_field :email, class: "w-full rounded border-gray-300", autofocus: true %>
          </div>

          <div class="mb-4">
            <%= form.label :password, class: "block text-sm font-medium mb-1" %>
            <%= form.password_field :password, class: "w-full rounded border-gray-300" %>
          </div>

          <%= form.submit "Sign In", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2 mb-3" %>

          <div class="text-center text-sm">
            <% if Clearance.configuration.allow_sign_up? %>
              <%= link_to "Create an account", sign_up_path %> &nbsp;&middot;&nbsp;
            <% end %>
            <% if Clearance.configuration.allow_password_reset? %>
              <%= link_to "Forgot password?", new_password_path %>
            <% end %>
          </div>
        <% end %>
      ERB
    end

    create_file "app/views/passwords/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Forgot Password" %>
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Forgot Password</h2>
            <%= form_for :password, url: passwords_path do |form| %>
              <div class="mb-4">
                <%= form.label :email, class: "block text-sm font-medium mb-1" %>
                <%= form.email_field :email, class: "w-full rounded border-gray-300", autofocus: true %>
              </div>
              <%= form.submit "Send Reset Link", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
        #{card_close}
      ERB
    end

    create_file "app/views/passwords/edit.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Change Your Password" %>
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Change Your Password</h2>
            <%= form_for :password_reset,
                  url: [@user, :password, token: @user.confirmation_token],
                  html: { method: :put } do |form| %>
              <div class="mb-4">
                <%= form.label :password, class: "block text-sm font-medium mb-1" %>
                <%= form.password_field :password, class: "w-full rounded border-gray-300", autofocus: true %>
              </div>
              <%= form.submit "Change Password", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
        #{card_close}
      ERB
    end

    create_file "app/views/users/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Create Account" %>
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Create Account</h2>
            <%= form_for @user do |form| %>
              <%= render partial: "/users/form", object: form %>
              <%= form.submit "Create Account", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2 mt-2" %>
            <% end %>
        #{card_close}
      ERB
    end

    create_file "app/views/users/_form.html.erb", force: true do
      <<~ERB
        <div class="mb-4">
          <%= form.label :email, class: "block text-sm font-medium mb-1" %>
          <%= form.email_field :email, class: "w-full rounded border-gray-300", autofocus: true %>
        </div>

        <div class="mb-4">
          <%= form.label :password, class: "block text-sm font-medium mb-1" %>
          <%= form.password_field :password, class: "w-full rounded border-gray-300" %>
        </div>
      ERB
    end
  else
    create_file "app/views/devise/sessions/new.html.erb", force: true do
      <<~ERB
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Sign In</h2>
            <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
              <div class="mb-4">
                <%= f.label :email, class: "block text-sm font-medium mb-1" %>
                <%= f.email_field :email, autofocus: true, class: "w-full rounded border-gray-300" %>
              </div>
              <div class="mb-4">
                <%= f.label :password, class: "block text-sm font-medium mb-1" %>
                <%= f.password_field :password, autocomplete: "current-password", class: "w-full rounded border-gray-300" %>
              </div>
              <%= f.submit "Sign In", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
            <div class="text-center text-sm mt-3"><%= render "devise/shared/links" %></div>
        #{card_close}
      ERB
    end

    create_file "app/views/devise/registrations/new.html.erb", force: true do
      <<~ERB
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Create Account</h2>
            <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
              <%= render "devise/shared/error_messages", resource: resource %>
              <div class="mb-4">
                <%= f.label :email, class: "block text-sm font-medium mb-1" %>
                <%= f.email_field :email, autofocus: true, class: "w-full rounded border-gray-300" %>
              </div>
              <div class="mb-4">
                <%= f.label :password, class: "block text-sm font-medium mb-1" %>
                <%= f.password_field :password, autocomplete: "new-password", class: "w-full rounded border-gray-300" %>
              </div>
              <div class="mb-4">
                <%= f.label :password_confirmation, class: "block text-sm font-medium mb-1" %>
                <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "w-full rounded border-gray-300" %>
              </div>
              <%= f.submit "Create Account", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
            <div class="text-center text-sm mt-3"><%= render "devise/shared/links" %></div>
        #{card_close}
      ERB
    end

    create_file "app/views/devise/passwords/new.html.erb", force: true do
      <<~ERB
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Forgot Password</h2>
            <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :post }) do |f| %>
              <div class="mb-4">
                <%= f.label :email, class: "block text-sm font-medium mb-1" %>
                <%= f.email_field :email, autofocus: true, class: "w-full rounded border-gray-300" %>
              </div>
              <%= f.submit "Send Reset Link", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
        #{card_close}
      ERB
    end

    create_file "app/views/devise/passwords/edit.html.erb", force: true do
      <<~ERB
        #{card_open}
            <h2 class="text-xl font-semibold text-center mb-4">Change Your Password</h2>
            <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :put }) do |f| %>
              <%= f.hidden_field :reset_password_token %>
              <div class="mb-4">
                <%= f.label :password, "New password", class: "block text-sm font-medium mb-1" %>
                <%= f.password_field :password, autocomplete: "new-password", class: "w-full rounded border-gray-300" %>
              </div>
              <div class="mb-4">
                <%= f.label :password_confirmation, class: "block text-sm font-medium mb-1" %>
                <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "w-full rounded border-gray-300" %>
              </div>
              <%= f.submit "Change Password", class: "w-full bg-indigo-600 hover:bg-indigo-500 text-white rounded py-2" %>
            <% end %>
        #{card_close}
      ERB
    end
  end
end
