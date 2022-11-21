defmodule Luminous.Dashboards.TestDashboardLive do
  @moduledoc false

  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Dashboard, TimeRange, Components}

  defmodule Variables do
    @moduledoc false

    @behaviour Variable
    @impl true
    def variable(:var1), do: ["a", "b", "c"]
    def variable(:var2), do: ["1", "2", "3"]
  end

  defmodule Queries do
    @moduledoc false

    @behaviour Query
    @impl true
    def query(:q1, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-19T10:00:00Z]}, {"foo", 10}, {"bar", 100}],
        [{:time, ~U[2022-08-19T11:00:00Z]}, {"foo", 11}, {"bar", 101}]
      ]
      |> Query.Result.new(
        attrs: %{
          "foo" => Query.Attributes.define(type: :line),
          "bar" => Query.Attributes.define(type: :bar)
        }
      )
    end

    def query(:q2, _time_range, _variables) do
      Query.Result.new(666)
    end

    def query(:q3, time_range, _variables) do
      if DateTime.compare(time_range.to, ~U[2022-09-24T20:59:59Z]) == :eq do
        Query.Result.new(666)
      else
        Query.Result.new(Decimal.new(0))
      end
    end

    def query(:q4, _time_range, _variables) do
      Query.Result.new({"foo", 666}, attrs: %{"foo" => Query.Attributes.define(unit: "$")})
    end

    def query(:q5, _time_range, _variables) do
      Query.Result.new([{"foo", 66}, {"bar", 88}],
        attrs: %{
          "foo" => Query.Attributes.define(unit: "$"),
          "bar" => Query.Attributes.define(unit: "€")
        }
      )
    end

    def query(:q6, _time_range, _variables) do
      Query.Result.new("Just show this")
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
          ),
          Panel.define(
            :p4,
            "Panel 4",
            :stat,
            [Query.define(:q4, Queries)]
          ),
          Panel.define(
            :p5,
            "Panel 5",
            :stat,
            [Query.define(:q5, Queries)]
          ),
          Panel.define(
            :p6,
            "Panel 6",
            :stat,
            [Query.define(:q6, Queries)]
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
