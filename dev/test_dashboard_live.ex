defmodule Luminous.Dashboards.TestDashboardLive do
  @moduledoc false

  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, TimeRange, Components, Panel}
  alias Luminous.Dashboards.TestDashboardLive.{Queries, Variables}

  use Luminous.Live,
    title: "Test Dashboard",
    path: &Routes.test_dashboard_path/3,
    action: :index,
    time_zone: "Europe/Athens",
    panels: [
      Panel.define!(
        type: Panel.Chart,
        id: :p1,
        title: "Panel 1",
        queries: [Query.define(:q1, Queries)],
        ylabel: "Foo (μCKR)",
        data_attributes: %{
          "foo" => [type: :line, unit: "μCKR", fill: true],
          "bar" => [type: :bar, unit: "μCKR"]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p2,
        title: "Panel 2",
        queries: [Query.define(:q2, Queries)],
        data_attributes: %{
          "foo" => [unit: "$", title: "Bar ($)"]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p3,
        title: "Panel 3",
        queries: [Query.define(:q3, Queries)],
        data_attributes: %{
          foo: [unit: "$", title: "Bar ($)"]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p4,
        title: "Panel 4",
        queries: [Query.define(:q4, Queries)],
        data_attributes: %{"foo" => [unit: "$"]}
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p5,
        title: "Panel 5",
        queries: [Query.define(:q5, Queries)],
        data_attributes: %{
          "foo" => [unit: "$"],
          "bar" => [unit: "€"]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p6,
        title: "Panel 6",
        queries: [Query.define(:q6, Queries)]
      ),
      Panel.define!(
        type: Panel.Table,
        id: :p7,
        title: "Panel 7 (table)",
        queries: [Query.define(:q7, Queries)],
        data_attributes: %{
          "label" => [title: "Label", order: 0, halign: :center],
          "foo" => [title: "Foo", order: 1, halign: :right, table_totals: :sum],
          "bar" => [
            title: "Bar",
            order: 2,
            halign: :right,
            table_totals: :avg,
            number_formatting: [
              thousand_separator: ".",
              decimal_separator: ",",
              precision: 2
            ]
          ]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p8,
        title: "Panel 8 (stat with simple value)",
        queries: [Query.define(:q8, Queries)]
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p9,
        title: "Panel 9 (empty stat)",
        queries: [Query.define(:q9, Queries)]
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p10,
        title: "Panel 10 (stats as list of 2-tuples)",
        queries: [Query.define(:q10, Queries)],
        data_attributes: %{
          "foo" => [unit: "$"],
          "bar" => [unit: "€"]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :p11,
        title: "Panel 11 (nil stat)",
        queries: [Query.define(:q11, Queries)]
      )
    ],
    variables: [
      Variable.define!(id: :var1, label: "Var 1", module: Variables),
      Variable.define!(id: :var2, label: "Var 2", module: Variables),
      Variable.define!(id: :var3, label: "Var 3", module: Variables),
      Variable.define!(id: :multi_var, label: "Multi", module: Variables, type: :multi)
    ]

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
    def variable(:multi_var, _), do: ["north", "south", "east", "west"]
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
