# frozen_string_literal: true
# Applied by template.rb after db.rb, so every generated file (ours and
# Clearance's/Devise's generator output) exists. Rails' generated CI lints
# with bin/rubocop, so an app that fails it would fail CI on its first push.

after_bundle do
  run "bin/rubocop -a --format quiet" if File.exist?("bin/rubocop")
end
