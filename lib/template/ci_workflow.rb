# frozen_string_literal: true
# Applied by template.rb before rubocop.rb, which tidies what this writes.
# Adapts the test/system-test jobs Rails generated in ci.yml rather than
# owning them, so Rails' per-database services and env stay authoritative.

require "json"

after_bundle do
  workflow = ".github/workflows/ci.yml"
  next unless File.exist?(workflow)

  bun = File.exist?("bun.lock") || File.exist?("bun.lockb")

  # The runner's default yarn is 1.x, which can't read the Yarn 4 lockfile;
  # Corepack picks the version from package.json's packageManager.
  if File.exist?("package.json") && !bun
    node_steps = <<~YAML.gsub(/^(?=.)/, "      ")
      - name: Set up Node
        uses: actions/setup-node@v5
        with:
          node-version-file: .node-version
          # Its auto-cache runs yarn before Corepack is enabled, hitting Yarn 1.
          package-manager-cache: false

      # Node 25+ no longer bundles Corepack, and .node-version is whatever
      # Node scaffolded the app, so install it rather than rely on the image.
      - name: Enable Corepack
        run: npm install -g corepack && corepack enable

    YAML

    ["      - name: Run tests\n", "      - name: Run System Tests\n"].each do |anchor|
      verified_inject workflow, anchor, "ci_workflow.rb: #{anchor.strip.inspect} not found in #{workflow}; Node setup not added"
      # force: Thor otherwise skips the second job, since the text already exists.
      inject_into_file workflow, node_steps, before: anchor, force: true
    end

    yarn_version = `yarn --version`.strip
    if yarn_version.split(".").first.to_i >= 2
      package = JSON.parse(File.read("package.json"))
      package["packageManager"] = "yarn@#{yarn_version}"
      create_file "package.json", "#{JSON.pretty_generate(package)}\n", force: true
    end
  end

  next unless ENV.fetch("SCAFFOLD_TEST", "minitest") == "rspec"

  # `bundle exec rspec` skips the test:prepare hook that jsbundling and
  # cssbundling use to build assets, so a fresh checkout has none without it.
  {
    "run: bin/rails db:test:prepare test\n" =>
      %(run: bin/rails db:test:prepare test:prepare && bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"\n),
    "run: bin/rails db:test:prepare test:system\n" =>
      "run: bin/rails db:test:prepare test:prepare && bundle exec rspec spec/system\n"
  }.each do |from, to|
    verified_inject workflow, from, "ci_workflow.rb: #{from.strip.inspect} not found in #{workflow}; RSpec not wired into CI"
    gsub_file workflow, from, to
  end

  # Like Minitest's `bin/rails test`, the main step skips system specs, which
  # need Chrome; Rails' optional commented step is the one that runs them.
  if File.exist?("config/ci.rb")
    {
      %(step "Tests: Rails", "bin/rails test"\n) =>
        %(step "Tests: RSpec", "bin/rails test:prepare && bundle exec rspec --exclude-pattern 'spec/system/**/*_spec.rb'"\n),
      %(# step "Tests: System", "bin/rails test:system"\n) =>
        %(# step "Tests: System", "bin/rails test:prepare && bundle exec rspec spec/system"\n)
    }.each do |from, to|
      verified_inject "config/ci.rb", from, "ci_workflow.rb: #{from.strip.inspect} not found in config/ci.rb; RSpec not wired into bin/ci"
      gsub_file "config/ci.rb", from, to
    end
  end
end
