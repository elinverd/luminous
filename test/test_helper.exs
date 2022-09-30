Supervisor.start_link(
  [
    Luminous.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
