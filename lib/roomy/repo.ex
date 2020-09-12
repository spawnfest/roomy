defmodule Roomy.Repo do
  use Ecto.Repo,
    otp_app: :roomy,
    adapter: Ecto.Adapters.Postgres
end
