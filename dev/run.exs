###########################################
# Development Server for testing dashboards
###########################################

Task.async(fn ->
  children = [
    Luminous.Endpoint
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
|> Task.await(:infinity)
