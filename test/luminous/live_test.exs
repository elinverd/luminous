defmodule Luminous.LiveTest do
  use Luminous.ConnCase, async: true

  alias Luminous.Query.Attributes

  describe "panels" do
    test "sends the correct data to the chart panel", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view |> element("#panel-p1-title") |> render() =~ "Panel 1"

      expected_data = %{
        datasets: [
          %{
            attrs: %Attributes{
              fill: true,
              halign: :left,
              order: nil,
              title: nil,
              type: :line,
              unit: "μCKR"
            },
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
            attrs: %Attributes{
              fill: true,
              halign: :left,
              order: nil,
              title: nil,
              type: :bar,
              unit: "μCKR"
            },
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
        xlabel: nil,
        ylabel: "Foo (μCKR)",
        y_min_value: nil,
        y_max_value: nil
      }

      assert_push_event(view, "panel-p1::refresh-data", ^expected_data)
    end

    test "renders the correct data in the stat panels", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

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

    test "sends the correct data to the table panel", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view |> element("#panel-p7-title") |> render() =~ "Panel 7 (table)"

      expected_data = %{
        columns: [
          %{field: "label", headerHozAlign: :center, hozAlign: :center, title: "Label"},
          %{field: "foo", headerHozAlign: :right, hozAlign: :right, title: "Foo"},
          %{field: "bar", headerHozAlign: :right, hozAlign: :right, title: "Bar"}
        ],
        rows: [
          %{"bar" => 88, "foo" => 3, "label" => "row1"},
          %{"bar" => 99, "foo" => 4, "label" => "row2"}
        ]
      }

      assert_push_event(view, "panel-p7::refresh-data", ^expected_data)
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
        Routes.test_dashboard_path(conn, :index,
          var1: "a",
          var2: 1,
          var3: "test_param_val_1",
          from: from,
          to: to
        )
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
          var3: "test_param_val_1",
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
          var3: "test_param_val_1",
          from: DateTime.to_unix(tr.from),
          to: DateTime.to_unix(tr.to)
        )
      )
    end

    test "when a variable requires a param from the LV socket", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert has_element?(view, "#var3-dropdown li", "test_param_val_1")
      assert has_element?(view, "#var3-dropdown li", "test_param_val_2")
    end
  end
end
