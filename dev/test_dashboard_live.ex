defmodule Luminous.Dashboards.TestDashboardLive do
  use Phoenix.LiveView
  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Dashboard, TimeRange, Components}

  defmodule Variables do
    @behaviour Variable
    @impl true
    def variable(:var1), do: ["a", "b", "c"]
    def variable(:var2), do: ["1", "2", "3"]
  end

  defmodule Queries do
    @behaviour Query
    @impl true
    def query(:q1, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-19T10:00:00Z]}, {"foo", 10}, {"bar", 100}],
        [{:time, ~U[2022-08-19T11:00:00Z]}, {"foo", 11}, {"bar", 101}]
      ]
      |> Query.Result.new(var_attrs: %{"foo" => [type: :line], "bar" => [type: :bar]})
    end

    def query(:q2, _time_range, _variables) do
      Query.Result.new(666)
    end

    def query(:q3, time_range, _variables) do
      if DateTime.compare(time_range.to, ~U[2022-09-24T20:59:59Z]) == :eq do
        Query.Result.new(666)
      else
        Query.Result.new(0)
      end
    end
  end

  use Luminous.Live,
    dashboard:
      Dashboard.define(
        "Test Dashboard",
        &Routes.test_dashboard_path/3,
        :index,
        TimeRangeSelector.define(__MODULE__),
        panels: [
          Panel.define(
            :p1,
            "Panel 1",
            :chart,
            [Query.define(:q1, Queries)],
            unit: "μCKR",
            ylabel: "Foo (μCKR)"
          ),
          Panel.define(
            :p2,
            "Panel 2",
            :stat,
            [Query.define(:q2, Queries)],
            unit: "$",
            ylabel: "Bar ($)"
          ),
          Panel.define(
            :p3,
            "Panel 3",
            :stat,
            [Query.define(:q3, Queries)],
            unit: "$",
            ylabel: "Bar ($)"
          )
        ],
        variables: [
          Variable.define(:var1, "Var 1", Variables),
          Variable.define(:var2, "Var 2", Variables)
        ],
        time_zone: "Europe/Athens"
      )

  @behaviour TimeRangeSelector
  @impl true
  def default_time_range(tz), do: TimeRange.yesterday(tz)

  def render(assigns) do
    ~H"""
    <Components.dashboard socket={@socket} dashboard={@dashboard} stats={@stats} panel_statistics={@panel_statistics}/>
    """
  end
end
