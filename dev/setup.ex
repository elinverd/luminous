defmodule Luminous.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/", Luminous do
    pipe_through(:browser)

    live("/dashboard/test", Dashboards.TestDashboardLive, :index)
  end
end

defmodule Luminous.Endpoint do
  use Phoenix.Endpoint, otp_app: :luminous

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Luminous.Router)
end
