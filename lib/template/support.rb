# frozen_string_literal: true
# Applied by template.rb — first, before every other file that patches
# Rails-generated code via gsub_file/inject_into_class/inject_into_file.
# Thor's file-mutation helpers don't raise or warn when their target text
# doesn't match (e.g. because a Rails upgrade changed the generated
# boilerplate they anchor on) — they just silently no-op. This is the one
# place that check is implemented, instead of every file that patches
# generated code hand-rolling its own copy of it.

def verified_inject(file, expected_substring, message, hard_fail: false)
  return if File.read(file).include?(expected_substring)

  hard_fail ? raise(message) : say(message, :red)
end
