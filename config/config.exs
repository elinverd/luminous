import Config

config :phoenix, :json_library, Jason

# use time zones
# see: https://hexdocs.pm/elixir/DateTime.html#module-time-zone-database
# also: https://elixirschool.com/en/lessons/basics/date-time/#working-with-timezones
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
