###########################################
# Development Server for testing dashboards
###########################################

Task.async(fn ->
  children = [
    Luminous.Dev.Endpoint,
    {Phoenix.PubSub, name: Luminous.PubSub}
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
|> Task.await(:infinity)
