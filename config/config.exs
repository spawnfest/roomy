# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :roomy,
  ecto_repos: [Roomy.Repo]

# Configures the endpoint
config :roomy, RoomyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "meAUiXCHrL/4mCHCTx1V1ezANd7+TJ4hxs6jquw4L1zd5Zn8w4WgW3v0whLnXNzY",
  render_errors: [view: RoomyWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Roomy.PubSub,
  live_view: [signing_salt: "JBJllqIj"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
