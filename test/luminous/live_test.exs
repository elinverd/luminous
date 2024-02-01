defmodule Luminous.LiveTest do
  alias Luminous.TimeRange
  use Luminous.ConnCase, async: true

  alias Luminous.{Attributes, Query, Panel, TimeRange, Variable}

  defmodule Variables do
    @moduledoc false

    @behaviour Variable
    @impl true
    def variable(:var1, _), do: ["a", "b", "c"]
    def variable(:var2, _), do: ["1", "2", "3"]
    def variable(:multi_var, _), do: ["north", "south", "east", "west"]
    def variable(:empty, _), do: []
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

  def set_dashboard(view, dashboard), do: send(view.pid, {self(), {:dashboard, dashboard}})

  describe "panels" do
    test "sends the correct data to the chart panel", %{conn: conn} do
      dashboard = [
        title: "Test",
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
          )
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert view |> element("#panel-p1-title") |> render() =~ "Panel 1"

      schema = Attributes.Schema.data() ++ Panel.Chart.data_attributes()

      expected_data = %{
        datasets: [
          %{
            attrs:
              Attributes.parse!(
                [
                  fill: true,
                  type: :line,
                  unit: "μCKR"
                ],
                schema
              ),
            label: "foo",
            rows: [
              %{x: 1_660_903_200_000, y: Decimal.new(10)},
              %{x: 1_660_906_800_000, y: Decimal.new(11)}
            ],
            stats: %{
              avg: Decimal.new(11),
              label: "foo",
              max: Decimal.new(11),
              min: Decimal.new(10),
              n: 2,
              sum: Decimal.new(21)
            }
          },
          %{
            attrs:
              Attributes.parse!(
                [
                  type: :bar,
                  unit: "μCKR"
                ],
                schema
              ),
            label: "bar",
            rows: [
              %{x: 1_660_903_200_000, y: Decimal.new(100)},
              %{x: 1_660_906_800_000, y: Decimal.new(101)}
            ],
            stats: %{
              avg: Decimal.new(101),
              label: "bar",
              max: Decimal.new(101),
              min: Decimal.new(100),
              n: 2,
              sum: Decimal.new(201)
            }
          }
        ],
        stacked_x: false,
        stacked_y: false,
        time_zone: "Europe/Athens",
        xlabel: "",
        ylabel: "Foo (μCKR)",
        y_min_value: nil,
        y_max_value: nil
      }

      assert_push_event(view, "panel-p1::refresh-data", ^expected_data)
    end

    test "renders the correct data in the stat panels", %{conn: conn} do
      dashboard = [
        title: "Test",
        panels: [
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
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))
      set_dashboard(view, dashboard)

      assert view |> element("#panel-p2-title") |> render() =~ "Panel 2"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">666<"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">$<"
      assert view |> element("#panel-p2-stat-values") |> render() =~ "Bar ($)"

      assert view |> element("#panel-p4-title") |> render() =~ "Panel 4"
      assert view |> element("#panel-p4-stat-values") |> render() =~ ">666<"
      assert view |> element("#panel-p4-stat-values") |> render() =~ ">$<"

      assert view |> element("#panel-p5-title") |> render() =~ "Panel 5"
      assert view |> element("#panel-p5-stat-values") |> render() =~ ">66<"
      assert view |> element("#panel-p5-stat-values") |> render() =~ ">$<"
      assert view |> element("#panel-p5-stat-values") |> render() =~ ">88<"
      assert view |> element("#panel-p5-stat-values") |> render() =~ ">€<"

      assert view |> element("#panel-p6-title") |> render() =~ "Panel 6"
      assert view |> element("#panel-p6-stat-values") |> render() =~ ">Just show this<"

      assert view |> element("#panel-p8-title") |> render() =~ "Panel 8"
      assert view |> element("#panel-p8-stat-values") |> render() =~ ">11<"

      assert view |> element("#panel-p9-title") |> render() =~ "Panel 9"
      assert view |> element("#panel-p9-stat-values") |> render() =~ ">-<"

      assert view |> element("#panel-p10-title") |> render() =~ "Panel 10"
      assert view |> element("#panel-p10-stat-values") |> render() =~ ">452,64<"
      assert view |> element("#panel-p10-stat-values") |> render() =~ ">$<"
      assert view |> element("#panel-p10-stat-values") |> render() =~ ">260.238,4<"
      assert view |> element("#panel-p10-stat-values") |> render() =~ ">€<"

      assert view |> element("#panel-p11-title") |> render() =~ "Panel 11"
      assert view |> element("#panel-p11-stat-values") |> render() =~ ">-<"
    end

    test "does not push the event in the case of the stat panel", %{conn: conn} do
      dashboard = [
        title: "Test",
        panels: [
          Panel.define!(
            type: Panel.Stat,
            id: :p2,
            title: "Panel 2",
            queries: [Query.define(:q2, Queries)],
            data_attributes: %{
              "foo" => [unit: "$", title: "Bar ($)"]
            }
          )
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))
      set_dashboard(view, dashboard)

      # let's assert that we will not receive the message in the case of the Stat panel
      # not the most solid of tests but with a timeout of 500ms it should do the job

      assert %{proxy: {ref, _topic, _}} = view

      refute_receive {^ref,
                      {:push_event, "panel-p2::refresh-data",
                       %{stats: [%{title: "Bar ($)", unit: "$", value: 666}]}}},
                     200
    end

    test "sends the correct data to the table panel", %{conn: conn} do
      dashboard = [
        title: "Test",
        panels: [
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
          )
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))
      set_dashboard(view, dashboard)

      assert view |> element("#panel-p7-title") |> render() =~ "Panel 7 (table)"

      expected_data = %{
        columns: [
          %{
            field: "label",
            headerHozAlign: :center,
            hozAlign: :center,
            title: "Label"
          },
          %{
            field: "foo",
            headerHozAlign: :right,
            hozAlign: :right,
            title: "Foo",
            bottomCalc: :sum
          },
          %{
            field: "bar",
            headerHozAlign: :right,
            hozAlign: :right,
            title: "Bar",
            formatter: "money",
            formatterParams: %{decimal: ",", thousand: ".", precision: 2},
            bottomCalc: :avg,
            bottomCalcFormatter: "money",
            bottomCalcFormatterParams: %{decimal: ",", thousand: ".", precision: 2}
          }
        ],
        rows: [
          %{"bar" => 88, "foo" => 3, "label" => "row1"},
          %{"bar" => 99, "foo" => 4, "label" => "row2"}
        ]
      }

      assert_push_event(view, "panel-p7::refresh-data", ^expected_data)
    end

    test "sends the loading/loaded event to all panels", %{conn: conn} do
      dashboard = [
        title: "Test",
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
          )
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))
      set_dashboard(view, dashboard)

      assert_push_event(view, "panel:load:start", %{id: :p1})
      assert_push_event(view, "panel:load:start", %{id: :p2})

      assert_push_event(view, "panel:load:end", %{id: :p1})
      assert_push_event(view, "panel:load:end", %{id: :p2})
    end
  end

  describe "time range" do
    test "when the selected time range changes", %{conn: conn} do
      dashboard = [
        title: "Test",
        panels: [
          Panel.define!(
            type: Panel.Stat,
            id: :p3,
            title: "Panel 3",
            queries: [Query.define(:q3, Queries)],
            data_attributes: %{
              foo: [unit: "$", title: "Bar ($)"]
            }
          )
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))
      set_dashboard(view, dashboard)

      assert has_element?(view, "#panel-p3-title", "Panel 3")
      assert has_element?(view, "#panel-p3-stat-values", "0")
      assert has_element?(view, "#panel-p3-stat-values", "$")
      assert has_element?(view, "#panel-p3-stat-values", "Bar ($)")

      from = DateTime.new!(~D[2022-09-19], ~T[00:00:00], "Europe/Athens")
      to = DateTime.new!(~D[2022-09-24], ~T[23:59:59], "Europe/Athens")

      # select a different time range
      view
      |> element("#time-range-selector")
      |> render_hook("lmn_time_range_change", %{
        "from" => DateTime.to_iso8601(from),
        "to" => DateTime.to_iso8601(to)
      })

      refute has_element?(view, "#panel-p3-stat-values", "0")
      assert has_element?(view, "#panel-p3-stat-values", "666")
    end

    test "when a time range preset is selected", %{conn: conn} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :var1, label: "Var 1", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      view
      |> element("#time-range-preset-Yesterday")
      |> render_click()

      # we use "Europe/Athens" because this is the time zone defined in TestDashboardLive module
      yesterday = DateTime.now!("Europe/Athens") |> DateTime.to_date() |> Date.add(-1)

      from =
        yesterday
        |> DateTime.new!(~T[00:00:00], "Europe/Athens")
        |> DateTime.to_unix()

      to = DateTime.new!(yesterday, ~T[23:59:59], "Europe/Athens") |> DateTime.to_unix()

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          var1: "a",
          from: from,
          to: to
        )
      )
    end

    test "when the default time range preset is selected", %{conn: conn} do
      dashboard = [
        title: "Test"
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      view
      |> element("#time-range-preset-Default")
      |> render_click()

      default = TimeRange.default(TimeRange.default_time_zone())

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          from: DateTime.to_unix(default.from),
          to: DateTime.to_unix(default.to)
        )
      )
    end
  end

  describe "variables" do
    test "displays all current variable values", %{conn: conn} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :var1, label: "Var 1", module: Variables),
          Variable.define!(id: :var2, label: "Var 2", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert has_element?(view, "#var1-dropdown li", "a")
      assert has_element?(view, "#var2-dropdown li", "1")
    end

    test "when a variable value is selected", %{conn: conn} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :var1, label: "Var 1", module: Variables),
          Variable.define!(id: :var2, label: "Var 2", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      view |> element("#var1-b") |> render_click()

      # we use "Europe/Athens" because this is the time zone defined in TestDashboardLive module
      default = Luminous.TimeRange.default("Europe/Athens")

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          var1: "b",
          var2: 1,
          from: DateTime.to_unix(default.from),
          to: DateTime.to_unix(default.to)
        )
      )

      view |> element("#var2-3") |> render_click()

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          var1: "b",
          var2: 3,
          from: DateTime.to_unix(default.from),
          to: DateTime.to_unix(default.to)
        )
      )
    end

    test "should not display hidden variables", %{conn: conn} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :var1, label: "Var 1", module: Variables),
          Variable.define!(id: :var2, label: "Var 2", module: Variables, hidden: true),
          Variable.define!(id: :multi_var, label: "Multi", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert has_element?(view, "#var1-dropdown")
      refute has_element?(view, "#var2-dropdown")
      assert has_element?(view, "#multi_var-dropdown")
    end

    test "should handle current variable value that is nil", %{conn: conn} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :var1, label: "Var 1", module: Variables),
          Variable.define!(id: :empty, label: "Empty", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert view |> element("#empty-dropdown-label") |> render() =~ ">Empty: <"
    end
  end

  describe "multi-select variables" do
    setup do
      # we use "Europe/Athens" because this is the time zone defined in TestDashboardLive module
      default = Luminous.TimeRange.default("Europe/Athens")

      %{from: DateTime.to_unix(default.from), to: DateTime.to_unix(default.to)}
    end

    test "when a single value is selected", %{conn: conn, from: from, to: to} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :multi_var, type: :multi, label: "Multi", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert has_element?(view, "#multi_var-dropdown", "Multi: All")

      view
      |> element("#multi_var-dropdown")
      |> render_hook("lmn_variable_updated", %{variable: "multi_var", value: ["north"]})

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          multi_var: ["north"],
          from: from,
          to: to
        )
      )

      assert has_element?(view, "#multi_var-dropdown", "Multi: north")
    end

    test "when two values are selected", %{conn: conn, from: from, to: to} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :multi_var, type: :multi, label: "Multi", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert has_element?(view, "#multi_var-dropdown", "Multi: All")

      view
      |> element("#multi_var-dropdown")
      |> render_hook("lmn_variable_updated", %{variable: "multi_var", value: ["north", "south"]})

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index,
          multi_var: ["north", "south"],
          from: from,
          to: to
        )
      )

      assert has_element?(view, "#multi_var-dropdown", "Multi: 2 selected")
    end

    test "when no value is selected", %{conn: conn, from: from, to: to} do
      dashboard = [
        title: "Test",
        variables: [
          Variable.define!(id: :multi_var, type: :multi, label: "Multi", module: Variables)
        ]
      ]

      {:ok, view, _} = live(conn, Routes.dashboard_path(conn, :index))

      set_dashboard(view, dashboard)

      assert has_element?(view, "#multi_var-dropdown", "Multi: All")

      view
      |> element("#multi_var-dropdown")
      |> render_hook("lmn_variable_updated", %{variable: "multi_var", value: []})

      assert_patched(
        view,
        Routes.dashboard_path(conn, :index, multi_var: "none", from: from, to: to)
      )

      assert has_element?(view, "#multi_var-dropdown", "Multi: None")
    end
  end
end
