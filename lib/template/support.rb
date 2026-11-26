# frozen_string_literal: true
# Applied by template.rb — first, before every other file that patches
# Rails-generated code via gsub_file/inject_into_class/inject_into_file.
# Thor's file-mutation helpers don't raise or warn when their target text
# doesn't match (e.g. because a Rails upgrade changed the generated
# boilerplate they anchor on) — they just silently no-op. This is the one
# place that check is implemented, instead of every file that patches
# generated code hand-rolling its own copy of it.

# Anything the developer should act on goes through here, not `say`: printed
# mid-run, it scrolls off under later generators' output. Order in a group
# is kept; groups print setup notes, then warnings, then the next command.
END_NOTES = { notes: :yellow, warnings: :red, next_step: :green }.freeze
@end_notes = END_NOTES.transform_values { [] }

def note_for_end(message, group = :notes, color: END_NOTES.fetch(group))
  @end_notes.fetch(group) << [ message, color ]
end

# at_exit, not a final after_bundle: a failed generator aborts the process,
# and that's when the queued warnings matter most.
at_exit do
  @end_notes.each_value do |notes|
    notes.each { |message, color| say "\n#{message}", color }
  end
end

# Runs an install generator, moving its boxed readme to the end notes. It's a
# subprocess, so only reopening the real STDOUT captures it. STDERR stays live so
# errors show at once, which prints them above the replayed output.
def generate_deferring_readme(generator)
  require "tempfile"
  captured = Tempfile.new("generator_output")
  original_stdout = STDOUT.dup
  STDOUT.reopen(captured)
  STDOUT.sync = true

  begin
    generate generator
  ensure
    # In ensure, since a failed generator aborts (SystemExit), and its output
    # is the only explanation the developer gets.
    STDOUT.reopen(original_stdout)
    original_stdout.close
    before, readme, after = File.read(captured.path).split(/^[=*]{20,}[ \t]*(?:\r?\n|\z)/, 3)
    captured.close!

    print before
    if after
      print after
      note_for_end "Notes from #{generator} (this template already handles most of them; check the production mailer host):\n\n#{readme.strip}"
    elsif readme
      print readme
    end
  end
end

def verified_inject(file, expected_substring, message, hard_fail: false)
  return if File.read(file).include?(expected_substring)

  hard_fail ? raise(message) : note_for_end(message, :warnings)
end

# Shared by the home pages (view_styles/*) and the shipped system test,
# which asserts on this exact text — one definition so they can't drift.
def app_title
  File.basename(destination_root).split(/[-_]/).map(&:capitalize).join(" ")
end
