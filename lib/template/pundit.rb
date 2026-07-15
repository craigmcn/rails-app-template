# frozen_string_literal: true
# Applied by template.rb — always runs regardless of chosen options.

gem "pundit"

after_bundle do
  generate "pundit:install"

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    "  include Pundit::Authorization\n\n"
  end

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
end
