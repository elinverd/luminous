import Config

config :luminous, Luminous.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 5000],
  render_errors: [view: Luminous.ErrorView],
  code_reloader: true,
  debug_errors: true,
  check_origin: false,
  pubsub_server: Luminous.PubSub,
  live_reload: [
    patterns: [
      ~r"priv/static/assets/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/luminous/.*(ex)$",
      ~r"dev/.*(ex)$"
    ]
  ],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :phoenix, serve_endpoints: true
