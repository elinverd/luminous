defmodule Luminous.Dashboards.DemoDashboardLive do
  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Dashboard, TimeRange, Components}

  defmodule Variables do
    @behaviour Variable
    @impl true
    def variable(:multiplier_var), do: ["1", "10", "100"]
    def variable(:interval_var), do: ["hour", "day"]
  end

  defmodule Queries do
    @behaviour Query
    @impl true
    def query(:simple_time_series, time_range, variables) do
      interval =
        variables
        |> Variable.get_current_and_extract_value(:interval_var)
        |> String.to_existing_atom()

      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      time_range
      |> Luminous.Generator.generate(multiplier, interval, "simple variable")
      |> Query.Result.new()
    end

    def query(:multiple_time_series, time_range, variables) do
      interval =
        variables
        |> Variable.get_current_and_extract_value(:interval_var)
        |> String.to_existing_atom()

      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      time_range
      |> Luminous.Generator.generate(multiplier, interval, ["a", "b"])
      |> Enum.map(fn row ->
        a = Enum.find_value(row, fn {var, val} -> if var == "a", do: val end)
        b = Enum.find_value(row, fn {var, val} -> if var == "b", do: val end)
        [{"a-b", Decimal.sub(a, b)} | row]
      end)
      |> Query.Result.new(
        var_attrs: %{
          "a" => [type: :line, order: 0],
          "b" => [type: :line, order: 1],
          "a-b" => [type: :bar, order: 2]
        }
      )
    end

    def query(:multiple_time_series_with_stacking, time_range, variables) do
      interval =
        variables
        |> Variable.get_current_and_extract_value(:interval_var)
        |> String.to_existing_atom()

      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      time_range
      |> Luminous.Generator.generate(multiplier, interval, ["a", "b"])
      |> Enum.map(fn row ->
        a = Enum.find_value(row, fn {var, val} -> if var == "a", do: val end)
        b = Enum.find_value(row, fn {var, val} -> if var == "b", do: val end)
        [{"total", Decimal.add(a, b)} | row]
      end)
      |> Query.Result.new(
        var_attrs: %{
          "a" => [type: :bar, order: 0],
          "b" => [type: :bar, order: 1],
          "total" => [fill: false]
        }
      )
    end

    def query(:single_stat, _time_range, variables) do
      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      value =
        :rand.uniform()
        |> Decimal.from_float()
        |> Decimal.mult(multiplier)
        |> Decimal.round(2)

      Query.Result.new({"foo", value})
    end

    def query(:string_stat, %{from: from}, _variables) do
      s = Calendar.strftime(from, "%b %Y")

      Query.Result.new({"String stat", s})
    end

    def query(:more_stats, _time_range, variables) do
      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      Enum.map(1..2, fn i ->
        v =
          :rand.uniform()
          |> Decimal.from_float()
          |> Decimal.mult(multiplier)
          |> Decimal.round(2)

        {"var_#{i}", v}
      end)
      |> Query.Result.new()
    end
  end

  use Luminous.Live,
    dashboard:
      Dashboard.define(
        "Demo Dashboard",
        &Routes.demo_dashboard_path/3,
        :index,
        TimeRangeSelector.define(__MODULE__),
        panels: [
          Panel.define(
            :simple_time_series,
            "Simple Time Series",
            :chart,
            [Query.define(:simple_time_series, Queries)],
            unit: "μCKR",
            ylabel: "Description"
          ),
          Panel.define(
            :single_stat,
            "Single-stat panel",
            :stat,
            [Query.define(:single_stat, Queries)],
            unit: "μCKR"
          ),
          Panel.define(
            :multi_stat,
            "This is a multi-stat panel",
            :stat,
            [
              Query.define(:string_stat, Queries),
              Query.define(:more_stats, Queries)
            ]
          ),
          Panel.define(
            :multiple_time_series,
            "Multiple Time Series with Ordering",
            :chart,
            [Query.define(:multiple_time_series, Queries)],
            unit: "μCKR",
            ylabel: "Description"
          ),
          Panel.define(
            :multiple_time_series_with_stacking,
            "Multiple Time Series with Stacking",
            :chart,
            [Query.define(:multiple_time_series_with_stacking, Queries)],
            unit: "μCKR",
            ylabel: "Description",
            stacked_x: true,
            stacked_y: true
          )
        ],
        variables: [
          Variable.define(:multiplier_var, "Mutliplier", Variables),
          Variable.define(:interval_var, "Interval", Variables)
        ],
        time_zone: "UTC"
      )

  @behaviour TimeRangeSelector
  @impl true
  def default_time_range(tz), do: TimeRange.last_n_days(7, tz)

  def render(assigns) do
    ~H"""
    <Components.dashboard socket={@socket} dashboard={@dashboard} stats={@stats} panel_statistics={@panel_statistics}/>
    """
  end
end
