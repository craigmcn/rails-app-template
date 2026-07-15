# frozen_string_literal: true
# Applied by template.rb when --css=bootstrap (the default).

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
      <div class="px-4 py-5 text-center">
        <h1 class="display-5 fw-bold">#{app_title}</h1>
        <p class="col-lg-8 mx-auto lead">This app was scaffolded with rails-app-template.</p>
      </div>
    ERB
  end

  route 'root "home#index"'

  create_file "app/views/layouts/application.html.erb", force: true do
    sign_in_link, sign_out_button, sign_up_link, current_user_email, signed_in_check =
      if auth == "devise"
        [
          'link_to "Sign In", new_user_session_path, class: "nav-link"',
          'button_to "Sign Out", destroy_user_session_path, method: :delete, class: "btn btn-outline-light btn-sm my-1"',
          'link_to "Sign Up", new_user_registration_path, class: "btn btn-primary btn-sm my-1 ms-2"',
          "current_user.email",
          "user_signed_in?"
        ]
      else
        [
          'link_to "Sign In", sign_in_path, class: "nav-link"',
          'button_to "Sign Out", sign_out_path, method: :delete, class: "btn btn-outline-light btn-sm my-1"',
          'link_to "Sign Up", sign_up_path, class: "btn btn-primary btn-sm my-1 ms-2"',
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
          <nav class="navbar navbar-expand-lg navbar-dark bg-dark mb-0">
            <div class="container">
              <%= link_to "#{app_title}", root_path, class: "navbar-brand fw-bold" %>

              <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMain">
                <span class="navbar-toggler-icon"></span>
              </button>

              <div class="collapse navbar-collapse justify-content-end" id="navbarMain">
                <ul class="navbar-nav">
                  <% if #{signed_in_check} %>
                    <li class="nav-item">
                      <span class="nav-link text-light opacity-75"><%= #{current_user_email} %></span>
                    </li>
                    <li class="nav-item">
                      <%= #{sign_out_button} %>
                    </li>
                  <% else %>
                    <li class="nav-item">
                      <%= #{sign_in_link} %>
                    </li>
                    <li class="nav-item">
                      <%= #{sign_up_link} %>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>
          </nav>

          <main>
            <div class="container mt-4">
              <% if notice.present? %>
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                  <%= notice %>
                  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
              <% end %>
              <% if alert.present? %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                  <%= alert %>
                  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
              <% end %>

              <%= yield %>
            </div>
          </main>
        </body>
      </html>
    ERB
  end

  if auth == "clearance"
    create_file "app/views/sessions/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Sign In" %>

        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-4 text-center">Sign In</h2>
                <%= render partial: "/sessions/form" %>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/sessions/_form.html.erb", force: true do
      <<~ERB
        <%= form_for :session, url: session_path do |form| %>
          <div class="mb-3">
            <%= form.label :email, class: "form-label" %>
            <%= form.email_field :email, class: "form-control", autofocus: true %>
          </div>

          <div class="mb-3">
            <%= form.label :password, class: "form-label" %>
            <%= form.password_field :password, class: "form-control" %>
          </div>

          <div class="d-grid mb-3">
            <%= form.submit "Sign In", class: "btn btn-primary" %>
          </div>

          <div class="text-center small">
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

        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-2 text-center">Forgot Password</h2>
                <p class="text-center text-muted mb-4 small">Enter your email and we'll send you a reset link.</p>

                <%= form_for :password, url: passwords_path do |form| %>
                  <div class="mb-3">
                    <%= form.label :email, class: "form-label" %>
                    <%= form.email_field :email, class: "form-control", autofocus: true %>
                  </div>

                  <div class="d-grid mb-3">
                    <%= form.submit "Send Reset Link", class: "btn btn-primary" %>
                  </div>

                  <div class="text-center small">
                    <%= link_to "Back to Sign In", sign_in_path %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/passwords/edit.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Change Your Password" %>

        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-2 text-center">Change Your Password</h2>

                <%= form_for :password_reset,
                      url: [@user, :password, token: @user.confirmation_token],
                      html: { method: :put } do |form| %>
                  <div class="mb-3">
                    <%= form.label :password, class: "form-label" %>
                    <%= form.password_field :password, class: "form-control", autofocus: true %>
                  </div>

                  <div class="d-grid mb-3">
                    <%= form.submit "Change Password", class: "btn btn-primary" %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/users/new.html.erb", force: true do
      <<~ERB
        <% content_for :title, "Create Account" %>

        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-4 text-center">Create Account</h2>
                <%= form_for @user do |form| %>
                  <%= render partial: "/users/form", object: form %>
                  <div class="d-grid mt-3">
                    <%= form.submit "Create Account", class: "btn btn-primary" %>
                  </div>
                  <div class="text-center small mt-3">
                    Already have an account? <%= link_to "Sign in", sign_in_path %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/users/_form.html.erb", force: true do
      <<~ERB
        <div class="mb-3">
          <%= form.label :email, class: "form-label" %>
          <%= form.email_field :email, class: "form-control", autofocus: true %>
        </div>

        <div class="mb-3">
          <%= form.label :password, class: "form-label" %>
          <%= form.password_field :password, class: "form-control" %>
        </div>
      ERB
    end
  else
    create_file "app/views/devise/sessions/new.html.erb", force: true do
      <<~ERB
        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-4 text-center">Sign In</h2>
                <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
                  <div class="mb-3">
                    <%= f.label :email, class: "form-label" %>
                    <%= f.email_field :email, autofocus: true, class: "form-control" %>
                  </div>
                  <div class="mb-3">
                    <%= f.label :password, class: "form-label" %>
                    <%= f.password_field :password, autocomplete: "current-password", class: "form-control" %>
                  </div>
                  <div class="d-grid mb-3">
                    <%= f.submit "Sign In", class: "btn btn-primary" %>
                  </div>
                <% end %>
                <div class="text-center small">
                  <%= render "devise/shared/links" %>
                </div>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/devise/registrations/new.html.erb", force: true do
      <<~ERB
        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-4 text-center">Create Account</h2>
                <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
                  <%= render "devise/shared/error_messages", resource: resource %>
                  <div class="mb-3">
                    <%= f.label :email, class: "form-label" %>
                    <%= f.email_field :email, autofocus: true, class: "form-control" %>
                  </div>
                  <div class="mb-3">
                    <%= f.label :password, class: "form-label" %>
                    <%= f.password_field :password, autocomplete: "new-password", class: "form-control" %>
                  </div>
                  <div class="mb-3">
                    <%= f.label :password_confirmation, class: "form-label" %>
                    <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "form-control" %>
                  </div>
                  <div class="d-grid mb-3">
                    <%= f.submit "Create Account", class: "btn btn-primary" %>
                  </div>
                <% end %>
                <div class="text-center small">
                  <%= render "devise/shared/links" %>
                </div>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/devise/passwords/new.html.erb", force: true do
      <<~ERB
        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-2 text-center">Forgot Password</h2>
                <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :post }) do |f| %>
                  <div class="mb-3">
                    <%= f.label :email, class: "form-label" %>
                    <%= f.email_field :email, autofocus: true, class: "form-control" %>
                  </div>
                  <div class="d-grid mb-3">
                    <%= f.submit "Send Reset Link", class: "btn btn-primary" %>
                  </div>
                <% end %>
                <div class="text-center small">
                  <%= render "devise/shared/links" %>
                </div>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    create_file "app/views/devise/passwords/edit.html.erb", force: true do
      <<~ERB
        <div class="row justify-content-center mt-5">
          <div class="col-md-5">
            <div class="card shadow-sm">
              <div class="card-body p-4">
                <h2 class="card-title mb-2 text-center">Change Your Password</h2>
                <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :put }) do |f| %>
                  <%= f.hidden_field :reset_password_token %>
                  <div class="mb-3">
                    <%= f.label :password, "New password", class: "form-label" %>
                    <%= f.password_field :password, autocomplete: "new-password", class: "form-control" %>
                  </div>
                  <div class="mb-3">
                    <%= f.label :password_confirmation, class: "form-label" %>
                    <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "form-control" %>
                  </div>
                  <div class="d-grid mb-3">
                    <%= f.submit "Change Password", class: "btn btn-primary" %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      ERB
    end
  end
end
