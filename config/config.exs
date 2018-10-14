use Mix.Config

# Base config
config :servus,
  backends: [:testGame_1P, :testGame_2P],
  authMethods: [:AUTH_FB, :AUTH_SELF, :AUTH_ONLY],
  modules: [Echo],
  runAfterAuth: [],
  adapters: [
    tcp: 3334,
    web: 3335
  ],
  # Ecto DB
  ecto_repos: [Servus.Repo]

# Junit Formater Config
config :junit_formatter,
  report_file: "report_file_test.xml",
  report_dir: ".",
  print_report_file: true,
  prepend_project_name?: true

# Configuration for a connect-four game
config :servus,
  connect_four: %{
    players_per_game: 2,
    implementation: ConnectFour,
    queue_impl: PlayerQueue,
    queue_name: "conFour"
  }

# Configuration for a Testgame with 1P
config :servus,
  testGame_1P: %{
    players_per_game: 1,
    implementation: TestGame_1P,
    queue_impl: PlayerQueue,
    queue_name: "testGame_1p"
  }

# Configuration for Testgame with 2P
config :servus,
  testGame_2P: %{
    players_per_game: 2,
    implementation: TestGame_2P,
    queue_impl: PlayerQueue,
    queue_name: "testGame_2p"
  }

# JUST TEST Credentials!!!! NO Real Key or Application
config :servus,
  facebook: %{
    app_token: "1216077065136886|0b2b0ff3fde4bbe08fe58cd012904427",
    app_id: "1216077065136886",
    app_secret: "0b2b0ff3fde4bbe08fe58cd012904427"
  }

config :servus,
  player_userdata: %{
    picturepath: "../profiles/pictures"
  }

import_config "#{Mix.env()}.exs"
