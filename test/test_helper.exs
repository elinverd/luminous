Application.put_env(:luminous, Luminous.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  check_origin: false
)

Supervisor.start_link(
  [
    Luminous.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
