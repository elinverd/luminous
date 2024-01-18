defmodule Luminous.Dashboards.TestDashboardLive do
  @moduledoc false

  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Dashboard, TimeRange, Components, Panel}
  alias Luminous.Dashboards.TestDashboardLive.{Queries, Variables}

  use Luminous.Live,
    dashboard:
      Dashboard.define(
        "Test Dashboard",
        {&Routes.test_dashboard_path/3, :index},
        panels: [
          Panel.define(
            :p1,
            "Panel 1",
            :chart,
            [Query.define(:q1, Queries)],
            ylabel: "Foo (μCKR)"
          ),
          Panel.define(
            :p2,
            "Panel 2",
            :stat,
            [Query.define(:q2, Queries)]
          ),
          Panel.define(
            :p3,
            "Panel 3",
            :stat,
            [Query.define(:q3, Queries)]
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
          ),
          Panel.define(
            :p7,
            "Panel 7 (table)",
            :table,
            [Query.define(:q7, Queries)]
          ),
          Panel.define(
            :p8,
            "Panel 8 (stat with simple value)",
            :stat,
            [Query.define(:q8, Queries)]
          ),
          Panel.define(
            :p9,
            "Panel 9 (empty stat)",
            :stat,
            [Query.define(:q9, Queries)]
          ),
          Panel.define(
            :p10,
            "Panel 10 (stats as list of 2-tuples)",
            :stat,
            [Query.define(:q10, Queries)]
          ),
          Panel.define(
            :p11,
            "Panel 11 (nil stat)",
            :stat,
            [Query.define(:q11, Queries)]
          )
        ],
        variables: [
          Variable.define(:var1, "Var 1", Variables),
          Variable.define(:var2, "Var 2", Variables),
          Variable.define(:var3, "Var 3", Variables)
        ],
        time_zone: "Europe/Athens"
      )

  @impl true
  def parameters(_socket) do
    %{test_param: ["test_param_val_1", "test_param_val_2"]}
  end

  @impl true
  def default_time_range(tz), do: TimeRange.yesterday(tz)

  defmodule Variables do
    @moduledoc false

    @behaviour Variable
    @impl true
    def variable(:var1, _), do: ["a", "b", "c"]
    def variable(:var2, _), do: ["1", "2", "3"]
    def variable(:var3, %{test_param: values}), do: values
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
        Panel.Attributes.new!(Panel.Chart, %{
          "foo" => [type: :line, unit: "μCKR", fill: true],
          "bar" => [type: :bar, unit: "μCKR"]
        })
      )
    end

    def query(:q2, _time_range, _variables) do
      Query.Result.new(
        %{"foo" => 666},
        Panel.Attributes.new!(Panel.Stat, %{
          "foo" => [unit: "$", title: "Bar ($)"]
        })
      )
    end

    def query(:q3, time_range, _variables) do
      val =
        if DateTime.compare(time_range.to, ~U[2022-09-24T20:59:59Z]) == :eq do
          666
        else
          Decimal.new(0)
        end

      Query.Result.new(
        %{foo: val},
        Panel.Attributes.new!(Panel.Stat, %{
          foo: [unit: "$", title: "Bar ($)"]
        })
      )
    end

    def query(:q4, _time_range, _variables) do
      Query.Result.new(
        %{"foo" => 666},
        Panel.Attributes.new!(Panel.Stat, %{"foo" => [unit: "$"]})
      )
    end

    def query(:q5, _time_range, _variables) do
      Query.Result.new(
        %{"foo" => 66, "bar" => 88},
        Panel.Attributes.new!(Panel.Stat, %{
          "foo" => [unit: "$"],
          "bar" => [unit: "€"]
        })
      )
    end

    def query(:q6, _time_range, _variables) do
      Query.Result.new(%{"str" => "Just show this"})
    end

    def query(:q7, _time_range, _variables) do
      Query.Result.new(
        [
          %{"label" => "row1", "foo" => 3, "bar" => 88},
          %{"label" => "row2", "foo" => 4, "bar" => 99}
        ],
        Panel.Attributes.new!(Panel.Table, %{
          "label" => [title: "Label", order: 0, halign: :center],
          "foo" => [title: "Foo", order: 1, halign: :right, table_totals: :sum],
          "bar" => [
            title: "Bar",
            order: 2,
            halign: :right,
            table_totals: :avg,
            number_formatting: %Panel.Attributes.NumberFormatting{
              thousand_separator: ".",
              decimal_separator: ",",
              precision: 2
            }
          ]
        })
      )
    end

    def query(:q8, _time_range, _variables) do
      Query.Result.new(11)
    end

    def query(:q9, _time_range, _variables) do
      Query.Result.new([])
    end

    def query(:q10, _time_range, _variables) do
      Query.Result.new(
        [
          {"foo", "452,64"},
          {"bar", "260.238,4"}
        ],
        Panel.Attributes.new!(Panel.Stat, %{
          "foo" => [unit: "$"],
          "bar" => [unit: "€"]
        })
      )
    end

    def query(:q11, _time_range, _variables) do
      Query.Result.new([{"foo", nil}])
    end
  end

  def render(assigns) do
    ~H"""
    <Components.dashboard dashboard={@dashboard} panel_data={@panel_data} />
    """
  end
end
