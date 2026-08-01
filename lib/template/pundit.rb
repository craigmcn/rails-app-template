# frozen_string_literal: true
# Applied by template.rb — always runs regardless of chosen options.

gem "pundit", "~> 2.0"

after_bundle do
  generate "pundit:install"

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    "  include Pundit::Authorization\n\n"
  end

  verified_inject "app/controllers/application_controller.rb", "include Pundit::Authorization", <<~MESSAGE
    Couldn't confirm Pundit::Authorization was included in
    ApplicationController (the expected `class ApplicationController`
    anchor wasn't found). Pundit policies won't be usable until this is
    added by hand. See lib/template/pundit.rb.
  MESSAGE

  inject_into_file "app/controllers/application_controller.rb", before: /^end\n/ do
    <<~RUBY.gsub(/^(?=.)/, "  ")

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      private

      def user_not_authorized
        flash[:alert] = "You are not authorized to perform this action."
        redirect_back fallback_location: root_path
      end
    RUBY
  end

  verified_inject "app/controllers/application_controller.rb", "rescue_from Pundit::NotAuthorizedError", <<~MESSAGE
    Couldn't confirm the Pundit::NotAuthorizedError rescue_from handler
    was added to ApplicationController (the expected `before: /^end\\n/`
    anchor wasn't found). Unauthorized Pundit actions will raise instead
    of redirecting with a flash message. See lib/template/pundit.rb.
  MESSAGE
end
