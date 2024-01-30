defmodule Luminous.Test.DashboardLive do
  @moduledoc false

  alias Luminous.Test.Router.Helpers, as: Routes
  alias Luminous.{Dashboard, Components}

  use Luminous.Live,
    title: "This will be overriden by the tests",
    path: &Routes.dashboard_path/3,
    action: :index,
    time_zone: "Europe/Athens"

  @impl true
  # this function will be called from the tests in order
  # to set up the entire dashboard
  def handle_info({_task_ref, {:dashboard, schema}}, socket) do
    dashboard =
      schema
      |> Dashboard.define!()
      |> Dashboard.populate(socket.assigns)

    dashboard =
      Dashboard.update_current_time_range(dashboard, lmn_get_default_time_range(dashboard))

    socket =
      socket
      |> assign(dashboard: dashboard)
      |> push_patch(to: Dashboard.path(dashboard, socket, []))

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Components.dashboard dashboard={@dashboard} />
    """
  end
end
