defmodule Luminous.ComponentsTest do
  use Luminous.ConnCase, async: true

  describe "time range selector id" do
    test "canvas has correct id", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert has_element?(view, "canvas[time-range-selector-id=time-range-selector]")
    end
  end
end
