# frozen_string_literal: true
# Applied by template.rb after db.rb, so every generated file (ours and
# Clearance's/Devise's generator output) exists. Rails' generated CI lints
# with bin/rubocop, so an app that fails it would fail CI on its first push.

require "open3"

MAX_RUBOCOP_LINES = 50

after_bundle do
  next unless File.executable?("bin/rubocop")
  next if run("bin/rubocop -a --format quiet", abort_on_failure: false)

  # The plain check decides, not the -a run: CI runs this one, and -a's output
  # buries what's left among the offences it fixed. Thor's capture drops the status.
  remaining, status = Open3.capture2e("bin/rubocop", "--format", "quiet")
  next if status.success?

  # Capped so a long list can't bury the notes after it; the full list is
  # one bin/rubocop away, and the summary is the last line.
  lines = remaining.lines
  shown = remaining
  if lines.length > MAX_RUBOCOP_LINES
    cut = lines.length - MAX_RUBOCOP_LINES
    kept = lines.last(MAX_RUBOCOP_LINES)
    # Keep the "== path ==" header of the file the kept lines start inside.
    header = lines.first(cut).reverse.find { |line| line.start_with?("== ") }
    kept.unshift(header) if header && !kept.first.start_with?("== ")
    shown = "(#{cut} earlier lines cut; run bin/rubocop for them)\n#{kept.join}"
  end

  note_for_end <<~MESSAGE + shown, :warnings
    bin/rubocop still fails after autocorrecting, so the app's CI lint job
    will fail on its first push. Fix these by hand, then re-run bin/rubocop:

  MESSAGE
end
