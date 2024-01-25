defmodule Luminous.Test.DashboardLive do
  @moduledoc false

  alias Luminous.Test.Router.Helpers, as: Routes
  alias Luminous.{Dashboard, Variable, Query, TimeRange, Components}

  defmodule Variables do
    @moduledoc false

    @behaviour Variable
    @impl true
    def variable(:var1, _), do: ["a", "b", "c"]
    def variable(:var2, _), do: ["1", "2", "3"]
    def variable(:var3, %{test_param: values}), do: values
    def variable(:multi_var, _), do: ["north", "south", "east", "west"]

    def all(),
      do: [
        Variable.define!(id: :var1, label: "Var 1", module: __MODULE__),
        Variable.define!(id: :var2, label: "Var 2", module: __MODULE__),
        Variable.define!(id: :var3, label: "Var 3", module: __MODULE__),
        Variable.define!(id: :multi_var, label: "Multi", module: __MODULE__, type: :multi)
      ]
  end

  use Luminous.Live,
    title: "Test Dashboard",
    path: &Routes.dashboard_path/3,
    action: :index,
    time_zone: "Europe/Athens",
    variables: Variables.all()

  @impl true
  def handle_info({_task_ref, {:dashboard, schema}}, socket) do
    dashboard =
      schema
      |> Dashboard.define!()
      |> Dashboard.populate(parameters(socket))

    dashboard =
      Dashboard.update_current_time_range(
        dashboard,
        default_time_range(dashboard.time_zone)
      )

    socket =
      socket
      |> assign(dashboard: dashboard)
      |> push_patch(to: Dashboard.path(dashboard, socket, []))

    {:noreply, socket}
  end

  @impl true
  def parameters(_socket) do
    %{test_param: ["test_param_val_1", "test_param_val_2"]}
  end

  @impl true
  def default_time_range(tz), do: TimeRange.yesterday(tz)

  defmodule Queries do
    @moduledoc false

    @behaviour Query
    @impl true
    def query(:q1, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-19T10:00:00Z]}, {"foo", 10}, {"bar", 100}],
        [{:time, ~U[2022-08-19T11:00:00Z]}, {"foo", 11}, {"bar", 101}]
      ]
    end

    def query(:q2, _time_range, _variables) do
      %{"foo" => 666}
    end

    def query(:q3, time_range, _variables) do
      val =
        if DateTime.compare(time_range.to, ~U[2022-09-24T20:59:59Z]) == :eq do
          666
        else
          Decimal.new(0)
        end

      %{foo: val}
    end

    def query(:q4, _time_range, _variables) do
      %{"foo" => 666}
    end

    def query(:q5, _time_range, _variables) do
      %{"foo" => 66, "bar" => 88}
    end

    def query(:q6, _time_range, _variables) do
      %{"str" => "Just show this"}
    end

    def query(:q7, _time_range, _variables) do
      [
        %{"label" => "row1", "foo" => 3, "bar" => 88},
        %{"label" => "row2", "foo" => 4, "bar" => 99}
      ]
    end

    def query(:q8, _time_range, _variables) do
      11
    end

    def query(:q9, _time_range, _variables) do
      []
    end

    def query(:q10, _time_range, _variables) do
      [
        {"foo", "452,64"},
        {"bar", "260.238,4"}
      ]
    end

    def query(:q11, _time_range, _variables) do
      [{"foo", nil}]
    end
  end

  def render(assigns) do
    ~H"""
    <Components.dashboard dashboard={@dashboard} data={@panel_data} />
    """
  end
end
