import Config

config :phoenix, :json_library, Jason

# use time zones
# see: https://hexdocs.pm/elixir/DateTime.html#module-time-zone-database
# also: https://elixirschool.com/en/lessons/basics/date-time/#working-with-timezones
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# === ASSET PIPELINE ===
# targets:
# - default: will generate the assets under /priv/static/assets (for dev)
# - dist: will generate the assets under dist/ (for package)

# CSS
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ],
  dist: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../dist/luminous.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# JS
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  dist: [
    args: ~w(js/luminous.js --bundle --target=es2016 --format=cjs --outdir=../dist),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
