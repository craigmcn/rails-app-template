# frozen_string_literal: true
# Applied by template.rb unless --no-rack-attack was passed. Baseline request
# throttling — general rate limit plus a stricter one on the login endpoint,
# since credential-stuffing/brute-force is the throttle rack-attack exists
# for most often. Config only; no dependency on --auth beyond the login path.

gem "rack-attack", "~> 6.7"

after_bundle do
  auth = ENV.fetch("SCAFFOLD_AUTH", "clearance")
  login_path = auth == "devise" ? "/users/sign_in" : "/session"
  login_param = auth == "devise" ? "user" : "session"

  create_file "config/initializers/rack_attack.rb", force: true do
    <<~RUBY
      # frozen_string_literal: true

      class Rack::Attack
        throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
          req.ip
        end

        throttle("logins by ip", limit: 5, period: 20.seconds) do |req|
          req.ip if req.path == "#{login_path}" && req.post?
        end

        throttle("logins by email", limit: 5, period: 20.seconds) do |req|
          if req.path == "#{login_path}" && req.post?
            req.params["#{login_param}"]&.dig("email").presence
          end
        end

        self.throttled_responder = lambda do |request|
          retry_after = (request.env["rack.attack.match_data"] || {})[:period]
          headers = retry_after ? {"Content-Type" => "application/json", "Retry-After" => retry_after.to_s} : {"Content-Type" => "application/json"}
          [429, headers, [{error: "Too many requests. Try again shortly."}.to_json]]
        end
      end

      # Adding middleware here (rather than config/application.rb) works
      # because Rails builds the middleware stack from config.middleware
      # after all initializers have run, not at the point this line executes.
      Rails.application.config.middleware.use Rack::Attack
    RUBY
  end
end
