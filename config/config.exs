# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ring,
  ecto_repos: [Ring.Repo]

# Configures the endpoint
config :ring, Ring.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jFfaRH0ntSZzln7FR/2KcfvVI4aKR7YfWgcTuZn34V3wf9zySW7OHtAym2FCp0R0",
  render_errors: [view: Ring.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ring.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
