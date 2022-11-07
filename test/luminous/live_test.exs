defmodule Luminous.LiveTest do
  use Luminous.ConnCase, async: true

  alias Luminous.Query

  describe "panels" do
    test "sends the correct data to the chart panel", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view |> element("#panel-p1-title") |> render() =~ "Panel 1"

      expected_data = %{
        datasets: [
          %Query.DataSet{
            label: "foo",
            rows: [
              %{x: 1_660_903_200_000, y: Decimal.new(10)},
              %{x: 1_660_906_800_000, y: Decimal.new(11)}
            ],
            attrs: Query.Attributes.define(type: :line, unit: "μCKR", fill: true)
          },
          %Query.DataSet{
            label: "bar",
            rows: [
              %{x: 1_660_903_200_000, y: Decimal.new(100)},
              %{x: 1_660_906_800_000, y: Decimal.new(101)}
            ],
            attrs: Query.Attributes.define(type: :bar, unit: "μCKR", fill: true)
          }
        ],
        xlabel: nil,
        ylabel: "Foo (μCKR)",
        stacked_x: false,
        stacked_y: false,
        time_zone: "Europe/Athens"
      }

      assert_push_event(view, "panel-p1::refresh-data", ^expected_data)
    end

    test "renders the correct data in the stat panels", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view |> element("#panel-p2-title") |> render() =~ "Panel 2"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">666<"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">$<"
      # ylabel is not taken into account in stat panels
      refute view |> element("#panel-p2-stat-values") |> render() =~ "Bar ($)"

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
    end

    test "sends the loading/loaded event to all panels", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert_push_event(view, "panel:load:start", %{id: :p1})
      assert_push_event(view, "panel:load:start", %{id: :p2})

      assert_push_event(view, "panel:load:end", %{id: :p1})
      assert_push_event(view, "panel:load:end", %{id: :p2})
    end
  end

  describe "time range" do
    test "when the selected time range changes", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert has_element?(view, "#panel-p3-title", "Panel 3")
      assert has_element?(view, "#panel-p3-stat-values", "0")
      assert has_element?(view, "#panel-p3-stat-values", "$")
      # ylabel is not taken into account in stat panels
      refute has_element?(view, "#panel-p3-stat-values", "Bar ($)")

      from = DateTime.new!(~D[2022-09-19], ~T[00:00:00], "Europe/Athens")
      to = DateTime.new!(~D[2022-09-24], ~T[23:59:59], "Europe/Athens")

      # select a different time range
      view
      |> element("#time-range-selector")
      |> render_hook("time_range_change", %{
        "from" => DateTime.to_iso8601(from),
        "to" => DateTime.to_iso8601(to)
      })

      refute has_element?(view, "#panel-p3-stat-values", "0")
      assert has_element?(view, "#panel-p3-stat-values", "666")
    end

    test "when a time range preset is selected", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

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
        Routes.test_dashboard_path(conn, :index, var1: "a", var2: 1, from: from, to: to)
      )
    end
  end

  describe "variables" do
    test "displays all current variable values", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert has_element?(view, "#var1-dropdown li", "a")
      assert has_element?(view, "#var2-dropdown li", "1")
    end

    test "when a variable value is selected", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      view |> element("#var1-b") |> render_click()

      # we use "Europe/Athens" because this is the time zone defined in TestDashboardLive module
      tr = Luminous.TimeRange.yesterday("Europe/Athens")

      assert_patched(
        view,
        Routes.test_dashboard_path(conn, :index,
          var1: "b",
          var2: 1,
          from: DateTime.to_unix(tr.from),
          to: DateTime.to_unix(tr.to)
        )
      )

      view |> element("#var2-3") |> render_click()

      assert_patched(
        view,
        Routes.test_dashboard_path(conn, :index,
          var1: "b",
          var2: 3,
          from: DateTime.to_unix(tr.from),
          to: DateTime.to_unix(tr.to)
        )
      )
    end
  end
end
