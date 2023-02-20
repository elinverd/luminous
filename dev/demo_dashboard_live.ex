defmodule Luminous.Dashboards.DemoDashboardLive do
  @moduledoc """
  This module demonstrates the functionality of a dashboard using `Luminous.Live`.
  """

  alias Luminous.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Dashboard, TimeRange, Components}

  defmodule Variables do
    @moduledoc """
    This is where we implement the `Luminous.Variable` behaviour, i.e. define
    the dashboard's variables displayed as dropdowns in the view

    The first value in each list is the default one.

    Values can be either simple (a single binary) or descriptive
    (label different than the value).

    Variables values are available within queries where they can serve
    as parameters.

    More details in `Luminous.Variable`.
    """

    @behaviour Variable
    @impl true
    def variable(:multiplier_var), do: ["1", "10", "100"]
    def variable(:interval_var), do: ["hour", "day"]
  end

  defmodule Queries do
    @moduledoc """
    This is where we implement the `Luminous.Query` behaviour, i.e. all queries
    that will be visualized in the dashboard's panels (a panel can
    have multiple queries).

    All queries have access to the current dashboard variable values
    and the selected time range.

    All queries must return a `Luminous.Query.Result` with optional attributes
    that specify the visual characteristics of the particular data set
    (see `Luminous.Query.Attributes`).

    More details in `Luminous.Query`.
    """

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
        attrs: %{
          "a" => Query.Attributes.define(type: :line, order: 0),
          "b" => Query.Attributes.define(type: :line, order: 1),
          "a-b" => Query.Attributes.define(type: :bar, order: 2)
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
        attrs: %{
          "a" => Query.Attributes.define(type: :bar, order: 0),
          "b" => Query.Attributes.define(type: :bar, order: 1),
          "total" => Query.Attributes.define(fill: false)
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

      Query.Result.new(%{"foo" => value},
        attrs: %{"foo" => Query.Attributes.define(title: "A Title")}
      )
    end

    def query(:string_stat, %{from: from}, _variables) do
      s = Calendar.strftime(from, "%b %Y")

      Query.Result.new(%{:string_stat => s},
        attrs: %{
          string_stat: Query.Attributes.define(title: "Just a date")
        }
      )
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
      |> Map.new()
      |> Query.Result.new(
        attrs: %{
          "var_1" => Query.Attributes.define(title: "Var A", order: 0),
          "var_2" => Query.Attributes.define(title: "Var B", order: 1)
        }
      )
    end

    def query(:tabular_data, %{from: t}, _variables) do
      data =
        case DateTime.compare(t, DateTime.utc_now()) do
          :lt ->
            []

          _ ->
            [
              %{"label" => "row1", "foo" => 3, "bar" => 88},
              %{"label" => "row2", "foo" => 4, "bar" => 99}
            ]
        end

      Query.Result.new(
        data,
        attrs: %{
          "label" => Query.Attributes.define(title: "Label", order: 0, halign: :center),
          "foo" => Query.Attributes.define(title: "Foo", order: 1, halign: :right),
          "bar" => Query.Attributes.define(title: "Bar", order: 2, halign: :right)
        }
      )
    end
  end

  # This is where the actual dashboard is defined (compile-time) by
  # specifying all of its components.

  # In general, a dashboard can have multiple panels and each panel
  # can have multiple queries. A dashboard also has a set of variables
  # and a time range component from which the user can select
  # arbitrary time windows.
  use Luminous.Live,
    dashboard:
      Dashboard.define(
        "Demo Dashboard",
        {&Routes.demo_dashboard_path/3, :index},
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
            :tabular_data,
            "Tabular Data",
            :table,
            [Query.define(:tabular_data, Queries)]
          ),
          Panel.define(
            :single_stat,
            "Single-stat panel",
            :stat,
            [Query.define(:single_stat, Queries)]
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
          Variable.define(:multiplier_var, "Multiplier", Variables),
          Variable.define(:interval_var, "Interval", Variables)
        ],
        time_zone: "UTC"
      )

  # a live dashboard also needs to specify its default time range
  @behaviour TimeRangeSelector
  @impl true
  def default_time_range(tz), do: TimeRange.last_n_days(7, tz)

  @doc false
  # Here, we make use of the default component (`dashboard`) that
  # renders all the other components on screen
  # A live dashboard can also specify custom layouts by making use of
  # individual components from `Luminous.Components` or completely
  # custom components
  def render(assigns) do
    ~H"""
    <Components.dashboard socket={@socket} dashboard={@dashboard} panel_data={@panel_data}/>
    """
  end
end
