use Mix.Config

config :logger,
  level: :error

config :servus, Servus.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "app",
  username: "db",
  password: "jUWDyRTtLCsHvwXq",
  hostname: "app_db",
  port: "5432"
