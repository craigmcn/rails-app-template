# frozen_string_literal: true
# Applied by template.rb — always runs. Rails' own generated config/puma.rb
# defaults every environment to 3 threads, but Puma's multi-threaded dev
# server races against Rails' lazy route-drawing/autoloading on the very
# first request(s) after boot: a browser's simultaneous initial requests
# (the page itself + favicon.ico + Chrome's devtools probe) can land on
# different threads while routes/constants are still being lazily
# initialized for the first time, producing an intermittent RoutingError or
# ArgumentError instead of a normal response — reproduced directly by firing
# concurrent requests at a freshly booted app; a single request never
# triggers it. Pinning development to one thread serializes those first
# requests and eliminates the race; other environments keep Rails' own
# RAILS_MAX_THREADS-driven default of 3.

gsub_file "config/puma.rb",
  'threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)' do
  <<~RUBY.strip
    rails_env = ENV.fetch("RAILS_ENV") { ENV.fetch("RACK_ENV", "development") }
    threads_count = rails_env == "development" ? ENV.fetch("RAILS_MAX_THREADS", 1) : ENV.fetch("RAILS_MAX_THREADS", 3)
  RUBY
end

verified_inject "config/puma.rb", "rails_env == \"development\"", <<~MESSAGE
  Couldn't confirm config/puma.rb's thread count was pinned to 1 for
  development (the expected `threads_count = ENV.fetch("RAILS_MAX_THREADS",
  3)` line wasn't found — Rails may have changed its generated wording).
  The dev server keeps Puma's default of 3 threads, which can intermittently
  500 on the very first page load (concurrent first requests racing Rails'
  lazy route-drawing/autoloading). See lib/template/puma_dev_threads.rb.
MESSAGE
