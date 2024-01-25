Supervisor.start_link(
  [
    Luminous.Test.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
