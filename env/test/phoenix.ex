defmodule Luminous.Test.Router do
  @moduledoc false

  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :put_root_layout, html: {Luminous.Test.LayoutView, :root}
    plug :fetch_session
  end

  scope "/", Luminous do
    pipe_through :browser

    live "/test", Test.DashboardLive, :index
  end
end

defmodule Luminous.Test.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :luminous

  socket("/live", Phoenix.LiveView.Socket)

  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Plug.Static,
    at: "/",
    from: :luminous,
    gzip: false,
    only: ~w(assets)
  )

  plug(Luminous.Test.Router)
end

defmodule Luminous.Test.ErrorView do
  @moduledoc false

  use Phoenix.View, root: "test/templates"

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule Luminous.Test.LayoutView do
  @moduledoc false

  use Phoenix.View, root: "dev"
  use Phoenix.Component

  alias Luminous.Test.Router.Helpers, as: Routes

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, shrink-to-fit=no, user-scalable=no"
        />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>Luminous</title>
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/assets/app.css")} />
        <script
          defer
          phx-track-static
          type="text/javascript"
          src={Routes.static_path(@conn, "/assets/app.js")}
        >
        </script>
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
