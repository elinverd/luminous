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
            rows: [%{x: 1_660_903_200_000, y: 10}, %{x: 1_660_906_800_000, y: 11}],
            type: :line,
            fill: true
          },
          %Query.DataSet{
            label: "bar",
            rows: [%{x: 1_660_903_200_000, y: 100}, %{x: 1_660_906_800_000, y: 101}],
            type: :bar,
            fill: true
          }
        ],
        unit: "μCKR",
        xlabel: nil,
        ylabel: "Foo (μCKR)",
        stacked_x: false,
        stacked_y: false,
        time_zone: "Europe/Athens"
      }

      assert_push_event(view, "panel-p1::refresh-data", ^expected_data)
    end

    test "renders the correct data in the stat panel", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view |> element("#panel-p2-title") |> render() =~ "Panel 2"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">666<"
      assert view |> element("#panel-p2-stat-values") |> render() =~ ">$<"
      assert view |> element("#panel-p2-stat-values") |> render() =~ "Bar ($)"
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
      assert has_element?(view, "#panel-p3-stat-values", "Bar ($)")

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
  end

  describe "variables" do
    test "displays all current variable values", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert has_element?(view, "#var1-dropdown li", "a")
      assert has_element?(view, "#var2-dropdown li", "1")
    end
  end
end
