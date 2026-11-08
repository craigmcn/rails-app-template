# frozen_string_literal: true
# Applied by template.rb when --action-text was passed. Only ever applied
# alongside active_storage.rb (bin/new-rails-app forces --active-storage on
# whenever --action-text is chosen, since Action Text's rich_text table
# references active_storage_blobs). Rails' own installer is aware of the
# chosen --javascript bundler and wires the Trix editor accordingly
# (importmap pin vs. yarn package + JS import), so this doesn't need to
# branch on JAVASCRIPT itself.

after_bundle do
  generate "action_text:install"
end
