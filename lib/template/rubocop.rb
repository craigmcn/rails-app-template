# frozen_string_literal: true
# Applied by template.rb after db.rb, so every generated file (ours and
# Clearance's/Devise's generator output) exists. Rails' generated CI lints
# with bin/rubocop, so an app that fails it would fail CI on its first push.

after_bundle do
  next unless File.exist?("bin/rubocop")
  next if run("bin/rubocop -a --format quiet", abort_on_failure: false)

  # A second run, since the first one's output buries what's left to fix
  # among the offences it corrected.
  remaining = run("bin/rubocop --format quiet", capture: true, verbose: false, abort_on_failure: false)

  note_for_end <<~MESSAGE + remaining, :warnings
    bin/rubocop still fails after autocorrecting, so the app's CI lint job
    will fail on its first push. Fix these by hand, then re-run bin/rubocop:

  MESSAGE
end
