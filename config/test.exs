use Mix.Config

config :logger,
  # level: :info
  level: :debug

config :servus, Servus.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "app",
  username: "db",
  password: "jUWDyRTtLCsHvwXq",
  hostname: "127.0.0.1",
  port: "5432"
