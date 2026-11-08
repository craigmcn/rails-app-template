# frozen_string_literal: true
# Applied by template.rb unless --no-pagy was passed. Pagy is a runtime
# dependency (used by controllers/views, not just dev tooling), so it lives
# in the main Gemfile group rather than alongside Bullet/letter_opener in
# ci.rb. Wires the bootstrap/bulma nav-helper extra when the chosen --css
# matches one Pagy ships an extra for (Pagy has never shipped a tailwind
# extra — tailwind's utility classes style the default `pagy_nav` markup
# fine as-is); other --css values get plain `pagy_nav`, same fallback
# pattern as lib/template/view_styles.
#
# Pinned to the 9.x line deliberately: Pagy 43 (current as of this
# writing) is a ground-up rewrite (`Pagy::Method`, no more Backend/Frontend
# modules or the extras mechanism at all) that would need this file
# rewritten from scratch, not just re-pinned. Revisit once 43's API has
# settled and is well-documented enough to port to confidently.

gem "pagy", "~> 9.0"

after_bundle do
  css = ENV.fetch("SCAFFOLD_CSS", "bootstrap")
  css_extra = {"bootstrap" => "pagy/extras/bootstrap", "bulma" => "pagy/extras/bulma"}[css]

  create_file "config/initializers/pagy.rb", force: true do
    <<~RUBY
      # frozen_string_literal: true

      require "pagy/extras/metadata"
      #{"require \"#{css_extra}\"\n" if css_extra}
      Pagy::DEFAULT[:limit] = 20
    RUBY
  end

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    "  include Pagy::Backend\n"
  end

  verified_inject "app/controllers/application_controller.rb", "include Pagy::Backend", <<~MESSAGE
    Couldn't confirm Pagy::Backend was included in ApplicationController
    (the expected `class ApplicationController` anchor wasn't found).
    Controllers won't have access to the `pagy` method. See
    lib/template/pagy.rb.
  MESSAGE

  inject_into_module "app/helpers/application_helper.rb", "ApplicationHelper" do
    "  include Pagy::Frontend\n"
  end

  verified_inject "app/helpers/application_helper.rb", "include Pagy::Frontend", <<~MESSAGE
    Couldn't confirm Pagy::Frontend was included in ApplicationHelper (the
    expected `module ApplicationHelper` anchor wasn't found). Views won't
    have access to `pagy_nav`/`pagy_info`. See lib/template/pagy.rb.
  MESSAGE
end
