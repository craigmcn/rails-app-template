# frozen_string_literal: true
# Applied by template.rb for --css values without dedicated styling
# (bulma, postcss, sass, or no --css at all). Produces plain, unstyled
# but fully functional markup.

auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")
app_title = File.basename(destination_root).split(/[-_]/).map(&:capitalize).join(" ")

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
      <h1>#{app_title}</h1>
      <p>This app was scaffolded with rails-app-template.</p>
    ERB
  end

  route 'root "home#index"'

  create_file "app/views/layouts/application.html.erb", force: true do
    sign_in_link, sign_out_button, sign_up_link, current_user_email, signed_in_check =
      if auth == "devise"
        [
          'link_to "Sign In", new_user_session_path',
          'button_to "Sign Out", destroy_user_session_path, method: :delete',
          'link_to "Sign Up", new_user_registration_path',
          "current_user.email",
          "user_signed_in?"
        ]
      else
        [
          'link_to "Sign In", sign_in_path',
          'button_to "Sign Out", sign_out_path, method: :delete',
          'link_to "Sign Up", sign_up_path',
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

        <body>
          <nav>
            <%= link_to "#{app_title}", root_path %>
            <% if #{signed_in_check} %>
              <span><%= #{current_user_email} %></span>
              <%= #{sign_out_button} %>
            <% else %>
              <%= #{sign_in_link} %>
              <%= #{sign_up_link} %>
            <% end %>
          </nav>

          <main>
            <% if notice.present? %>
              <p><%= notice %></p>
            <% end %>
            <% if alert.present? %>
              <p><%= alert %></p>
            <% end %>

            <%= yield %>
          </main>
        </body>
      </html>
    ERB
  end

  if auth == "clearance"
    create_file "app/views/sessions/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Sign In" %>
        <h1>Sign In</h1>
        <%= render partial: "/sessions/form" %>
      ERB
    end

    create_file "app/views/sessions/_form.html.erb", force: true do
      <<~ERB
        <%= form_for :session, url: session_path do |form| %>
          <p>
            <%= form.label :email %><br>
            <%= form.email_field :email, autofocus: true %>
          </p>
          <p>
            <%= form.label :password %><br>
            <%= form.password_field :password %>
          </p>
          <p><%= form.submit "Sign In" %></p>
          <p>
            <% if Clearance.configuration.allow_sign_up? %>
              <%= link_to "Create an account", sign_up_path %>
            <% end %>
            <% if Clearance.configuration.allow_password_reset? %>
              <%= link_to "Forgot password?", new_password_path %>
            <% end %>
          </p>
        <% end %>
      ERB
    end

    create_file "app/views/passwords/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Forgot Password" %>
        <h1>Forgot Password</h1>
        <%= form_for :password, url: passwords_path do |form| %>
          <p>
            <%= form.label :email %><br>
            <%= form.email_field :email, autofocus: true %>
          </p>
          <p><%= form.submit "Send Reset Link" %></p>
        <% end %>
      ERB
    end

    create_file "app/views/passwords/edit.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Change Your Password" %>
        <h1>Change Your Password</h1>
        <%= form_for :password_reset,
              url: [@user, :password, token: @user.confirmation_token],
              html: { method: :put } do |form| %>
          <p>
            <%= form.label :password %><br>
            <%= form.password_field :password, autofocus: true %>
          </p>
          <p><%= form.submit "Change Password" %></p>
        <% end %>
      ERB
    end

    create_file "app/views/users/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Create Account" %>
        <h1>Create Account</h1>
        <%= form_for @user do |form| %>
          <%= render partial: "/users/form", object: form %>
          <p><%= form.submit "Create Account" %></p>
        <% end %>
      ERB
    end

    create_file "app/views/users/_form.html.erb", force: true do
      <<~ERB
        <p>
          <%= form.label :email %><br>
          <%= form.email_field :email, autofocus: true %>
        </p>
        <p>
          <%= form.label :password %><br>
          <%= form.password_field :password %>
        </p>
      ERB
    end
  else
    create_file "app/views/devise/sessions/new.html.erb", force: true do
      <<~ERB
        <h1>Sign In</h1>
        <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
          <p>
            <%= f.label :email %><br>
            <%= f.email_field :email, autofocus: true %>
          </p>
          <p>
            <%= f.label :password %><br>
            <%= f.password_field :password, autocomplete: "current-password" %>
          </p>
          <p><%= f.submit "Sign In" %></p>
        <% end %>
        <%= render "devise/shared/links" %>
      ERB
    end

    create_file "app/views/devise/registrations/new.html.erb", force: true do
      <<~ERB
        <h1>Create Account</h1>
        <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
          <%= render "devise/shared/error_messages", resource: resource %>
          <p>
            <%= f.label :email %><br>
            <%= f.email_field :email, autofocus: true %>
          </p>
          <p>
            <%= f.label :password %><br>
            <%= f.password_field :password, autocomplete: "new-password" %>
          </p>
          <p>
            <%= f.label :password_confirmation %><br>
            <%= f.password_field :password_confirmation, autocomplete: "new-password" %>
          </p>
          <p><%= f.submit "Create Account" %></p>
        <% end %>
        <%= render "devise/shared/links" %>
      ERB
    end

    create_file "app/views/devise/passwords/new.html.erb", force: true do
      <<~ERB
        <h1>Forgot Password</h1>
        <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :post }) do |f| %>
          <p>
            <%= f.label :email %><br>
            <%= f.email_field :email, autofocus: true %>
          </p>
          <p><%= f.submit "Send Reset Link" %></p>
        <% end %>
      ERB
    end

    create_file "app/views/devise/passwords/edit.html.erb", force: true do
      <<~ERB
        <h1>Change Your Password</h1>
        <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :put }) do |f| %>
          <%= f.hidden_field :reset_password_token %>
          <p>
            <%= f.label :password, "New password" %><br>
            <%= f.password_field :password, autocomplete: "new-password" %>
          </p>
          <p>
            <%= f.label :password_confirmation %><br>
            <%= f.password_field :password_confirmation, autocomplete: "new-password" %>
          </p>
          <p><%= f.submit "Change Password" %></p>
        <% end %>
      ERB
    end
  end
end
