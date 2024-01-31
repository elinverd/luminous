defmodule Luminous.DashboardTest do
  use Luminous.ConnCase, async: true

  alias Luminous.{Dashboard, TimeRange, Variable}

  defmodule Variables do
    @behaviour Variable
    @impl true
    def variable(:foo, _), do: ["a"]
  end

  describe "path/3" do
    test "when the current time range is nil and no time range is passed in params" do
      dashboard = Dashboard.define!(title: "Test", path: &Routes.dashboard_path/3, action: :index)

      assert dashboard |> Dashboard.get_current_time_range() |> is_nil()

      assert Dashboard.path(dashboard, Luminous.Test.Endpoint) ==
               Routes.dashboard_path(Luminous.Test.Endpoint, :index)
    end

    test "the current time range should be preserved if not overriden in params" do
      dashboard =
        Dashboard.define!(
          title: "Test",
          path: &Routes.dashboard_path/3,
          action: :index,
          variables: [
            Variable.define!(id: :foo, label: "Foo", module: Variables)
          ]
        )
        |> Dashboard.populate(%{})

      current = TimeRange.last_n_days(7, dashboard.time_zone)
      dashboard = Dashboard.update_current_time_range(dashboard, current)
      assert Dashboard.get_current_time_range(dashboard) == current

      current_unix = TimeRange.to_unix(current)

      expected_path =
        Routes.dashboard_path(Luminous.Test.Endpoint, :index,
          foo: "bar",
          from: current_unix.from,
          to: current_unix.to
        )

      assert Dashboard.path(dashboard, Luminous.Test.Endpoint, foo: "bar") == expected_path
    end

    test "the current time range should be updated if overriden in params" do
      dashboard = Dashboard.define!(title: "Test", path: &Routes.dashboard_path/3, action: :index)

      # let's set a value first
      current = TimeRange.last_n_days(7, dashboard.time_zone)
      dashboard = Dashboard.update_current_time_range(dashboard, current)
      assert Dashboard.get_current_time_range(dashboard) == current

      # let's call path with new values
      new_current = TimeRange.last_month(dashboard.time_zone)
      new_current_unix = TimeRange.to_unix(new_current)

      expected_path =
        Routes.dashboard_path(Luminous.Test.Endpoint, :index,
          from: new_current_unix.from,
          to: new_current_unix.to
        )

      assert Dashboard.path(
               dashboard,
               Luminous.Test.Endpoint,
               from: new_current.from,
               to: new_current.to
             ) == expected_path
    end
  end
end
