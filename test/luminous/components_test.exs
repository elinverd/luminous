defmodule Luminous.ComponentsTest do
  use Luminous.ConnCase, async: true

  describe "time range selector id" do
    test "canvas has correct id", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.test_dashboard_path(conn, :index))

      assert view
             |> element("canvas[time-range-selector-id=time-range-selector]")
             |> has_element?()
    end
  end
end
