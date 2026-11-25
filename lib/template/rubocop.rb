# frozen_string_literal: true
# Applied by template.rb after db.rb, so every generated file (ours and
# Clearance's/Devise's generator output) exists. Rails' generated CI lints
# with bin/rubocop, so an app that fails it would fail CI on its first push.

require "open3"

after_bundle do
  next unless File.executable?("bin/rubocop")
  next if run("bin/rubocop -a --format quiet", abort_on_failure: false)

  # The plain check decides, not the -a run: CI runs this one, and -a's output
  # buries what's left among the offences it fixed. Thor's capture drops the status.
  remaining, status = Open3.capture2e("bin/rubocop", "--format", "quiet")
  next if status.success?

  say <<~MESSAGE, :red
    bin/rubocop still fails after autocorrecting, so the app's CI lint job
    will fail on its first push. Fix these by hand, then re-run bin/rubocop:

  MESSAGE
  say remaining, :red
end
