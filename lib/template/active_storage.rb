# frozen_string_literal: true
# Applied by template.rb when --active-storage was passed (or implied by
# --action-text — see bin/new-rails-app). Active Storage itself ships with
# every Rails app (config/storage.yml and the :local dev/test service
# already exist); running the installer only adds the migration for the
# active_storage_blobs/attachments/variant_records tables, which db.rb's
# final db:prepare picks up along with every other migration.
#
# Unlike Action Text, Active Storage's installer is a rake task
# (lib/tasks/activestorage.rake), not a Thor generator — `generate
# "active_storage:install"` raises Rails::Command::CorrectableNameError.

after_bundle do
  rails_command "active_storage:install"
end
