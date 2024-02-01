defmodule Luminous.DashboardTest do
  use Luminous.ConnCase, async: true

  alias Luminous.{Dashboard, TimeRange, Variable}

  defmodule Variables do
    @behaviour Variable
    @impl true
    def variable(:foo, _), do: ["a"]
  end

  describe "url_params/2" do
    test "the url params should include the non-hidden variables" do
      dashboard =
        Dashboard.define!(
          title: "Test",
          variables: [
            Variable.define!(hidden: false, id: :foo, label: "Foo", module: Variables)
          ]
        )
        |> Dashboard.populate(%{})

      assert [foo: "a"] = Dashboard.url_params(dashboard)
    end

    test "the path should exclude the hidden variables" do
      dashboard =
        Dashboard.define!(
          title: "Test",
          variables: [
            Variable.define!(hidden: true, id: :foo, label: "Foo", module: Variables)
          ]
        )
        |> Dashboard.populate(%{})

      assert Enum.empty?(Dashboard.url_params(dashboard))
    end

    test "when the current time range is nil and no time range is passed in params" do
      dashboard = Dashboard.define!(title: "Test")

      assert dashboard |> Dashboard.get_current_time_range() |> is_nil()

      assert Enum.empty?(Dashboard.url_params(dashboard))
    end

    test "the current time range should be preserved if not overriden in params" do
      dashboard =
        Dashboard.define!(
          title: "Test",
          variables: [
            Variable.define!(id: :foo, label: "Foo", module: Variables)
          ]
        )
        |> Dashboard.populate(%{})

      current = TimeRange.last_n_days(7, dashboard.time_zone)
      dashboard = Dashboard.update_current_time_range(dashboard, current)
      assert Dashboard.get_current_time_range(dashboard) == current

      %{from: from, to: to} = TimeRange.to_unix(current)

      assert [foo: "bar", from: ^from, to: ^to] = Dashboard.url_params(dashboard, foo: "bar")
    end

    test "the current time range should be updated if overriden in params" do
      dashboard = Dashboard.define!(title: "Test")

      # let's set a value first
      current = TimeRange.last_n_days(7, dashboard.time_zone)
      dashboard = Dashboard.update_current_time_range(dashboard, current)
      assert Dashboard.get_current_time_range(dashboard) == current

      # let's update the "current"
      %{from: nc_from, to: nc_to} = nc = TimeRange.last_month(dashboard.time_zone)
      %{from: ncu_from, to: ncu_to} = TimeRange.to_unix(nc)

      assert [from: ^ncu_from, to: ^ncu_to] =
               Dashboard.url_params(dashboard, from: nc_from, to: nc_to)
    end
  end
end
