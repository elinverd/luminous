defmodule Luminous.Dev.DashboardLive do
  @moduledoc false
  # This module demonstrates the functionality of a dashboard using `Luminous.Live`.

  alias Luminous.Dev.Router.Helpers, as: Routes
  alias Luminous.{Variable, Query, Components}

  defmodule Variables do
    @moduledoc false
    # This is where we implement the `Luminous.Variable` behaviour, i.e. define
    # the dashboard's variables displayed as dropdowns in the view

    # The first value in each list is the default one.

    # Values can be either simple (a single binary) or descriptive
    # (label different than the value).

    # Variables values are available within queries where they can serve
    # as parameters.

    # More details in `Luminous.Variable`.

    @behaviour Variable
    @impl true
    def variable(:multiplier_var, _) do
      ["1", "10", "100"]
    end

    def variable(:interval_var, _), do: ["hour", "day"]

    def variable(:region_var, _),
      do: [
        %{label: "north (l)", value: "north"},
        %{label: "south (l)", value: "south"},
        %{label: "east (l)", value: "east"},
        %{label: "west (l)", value: "west"},
        %{label: "north west (l)", value: "north west"},
        %{label: "south west (l)", value: "south west"},
        %{label: "north east (l)", value: "north east"},
        %{label: "south east (l)", value: "south east"}
      ]

    def variable(:region_var2, _), do: ["north2", "south2", "east2", "west2"]
  end

  defmodule Queries do
    @moduledoc false
    # This is where we implement the `Luminous.Query` behaviour, i.e. all queries
    # that will be visualized in the dashboard's panels (a panel can
    # have multiple queries).

    # All queries have access to the current dashboard variable values
    # and the selected time range.

    # More details in `Luminous.Query`.

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

      Luminous.Generator.generate(time_range, multiplier, interval, "simple variable")
    end

    def query(:multiple_time_series_with_diff, time_range, variables) do
      time_range
      |> multiple_time_series(variables)
      |> Enum.map(fn row ->
        a = Enum.find_value(row, fn {var, val} -> if var == "a", do: val end)
        b = Enum.find_value(row, fn {var, val} -> if var == "b", do: val end)
        [{"a-b", Decimal.sub(a, b)} | row]
      end)
    end

    def query(:multiple_time_series_with_total, time_range, variables) do
      time_range
      |> multiple_time_series(variables)
      |> Enum.map(fn row ->
        a = Enum.find_value(row, fn {var, val} -> if var == "a", do: val end)
        b = Enum.find_value(row, fn {var, val} -> if var == "b", do: val end)
        [{"total", Decimal.add(a, b)} | row]
      end)
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

      %{"foo" => value}
    end

    def query(:string_stat, %{from: from}, _variables) do
      s = Calendar.strftime(from, "%b %Y")

      %{:string_stat => s}
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
    end

    def query(:regions, _, variables) do
      variables
      |> Variable.find(:region_var)
      |> Variable.get_current()
    end

    def query(:tabular_data_1, %{from: t}, _variables) do
      case DateTime.compare(t, DateTime.utc_now()) do
        :lt ->
          [
            %{"foo" => 1301, "bar" => 88_555_666.2},
            %{"foo" => 1400, "bar" => 22_111_444.6332}
          ]

        _ ->
          [
            %{"foo" => 300.2, "bar" => 88999.4},
            %{"foo" => 400.234, "bar" => 99_888_777.21}
          ]
      end
    end

    def query(:tabular_data_2, %{from: t}, _variables) do
      case DateTime.compare(t, DateTime.utc_now()) do
        :lt ->
          [
            %{"label" => "row1"},
            %{"label" => "row2"}
          ]

        _ ->
          [
            %{"label" => "row1"},
            %{"label" => "row2"}
          ]
      end
    end

    def query(:variable_columns, time_range, _variables) do
      Luminous.Generator.generate(time_range, 100, :hour, ["var1", "var2"])
    end

    defp multiple_time_series(time_range, variables) do
      interval =
        variables
        |> Variable.get_current_and_extract_value(:interval_var)
        |> String.to_existing_atom()

      multiplier =
        variables
        |> Variable.get_current_and_extract_value(:multiplier_var)
        |> String.to_integer()

      Luminous.Generator.generate(time_range, multiplier, interval, ["a", "b"])
    end
  end

  # This is where the actual dashboard is defined (compile-time) by
  # specifying all of its components.
  alias Luminous.{Components, Panel, Query, Variable}

  # In general, a dashboard can have multiple panels and each panel
  # can have multiple queries. A dashboard also has a set of variables
  # and a time range component from which the user can select
  # arbitrary time windows.
  use Luminous.Live,
    title: "Demo Dashboard",
    time_zone: "UTC",
    panels: [
      Panel.define!(
        type: Panel.Chart,
        id: :simple_time_series,
        title: "Simple Time Series",
        queries: [
          Query.define(:simple_time_series, Queries)
        ],
        description: """
        This is a (possibly) long description of the particular
        dashboard. It is meant to explain in more depth with the user
        is seeing, the underlying assumptions etc.
        """,
        ylabel: "Description"
      ),
      Panel.define!(
        type: Panel.Table,
        id: :tabular_data,
        title: "Tabular Data",
        queries: [
          Query.define(:tabular_data_1, Queries),
          Query.define(:tabular_data_2, Queries)
        ],
        description: "This is a panel with tabular data",
        data_attributes: %{
          "label" => [title: "Label", order: 0, halign: :center],
          "foo" => [
            title: "Foo",
            order: 1,
            halign: :right,
            table_totals: :avg,
            number_formatting: [
              thousand_separator: ".",
              decimal_separator: ",",
              precision: 1
            ]
          ],
          "bar" => [
            title: "Bar",
            order: 2,
            halign: :right,
            table_totals: :sum,
            number_formatting: [
              thousand_separator: "_",
              decimal_separator: ".",
              precision: 4
            ]
          ]
        }
      ),
      Panel.define!(
        type: Panel.Table,
        id: :selected_regions,
        title: "Selected Regions",
        queries: [Query.define(:regions, Queries)],
        description:
          "This is a table that displays the selected regions and is dynamically updated every time the variable selection changes",
        data_attributes: %{
          "label" => [title: "Label", order: 0],
          "value" => [title: "Value", order: 1]
        }
      ),
      Panel.define!(
        type: Panel.Table,
        id: :variable_columns,
        title: "Tabular data with variable columns",
        queries: [Query.define(:variable_columns, Queries)],
        page_size: 24,
        description: """
        This is a panel with tabular data and variable number of columns.
        If the dataset is a list of maps, the maps' keys will be used as column titles.
        If the dataset is a list of lists of tuples, the tuples' first element will be
        used as column titles.
        In the latter case, the ordering of the tuples inside the lists will determine
        the ordering of the columns.
        """
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :single_stat,
        title: "Single-stat panel",
        queries: [Query.define(:single_stat, Queries)],
        data_attributes: %{
          "foo" => [title: "Just a date", order: 0]
        }
      ),
      Panel.define!(
        type: Panel.Stat,
        id: :multi_stat,
        title: "This is a multi-stat panel",
        queries: [
          Query.define(:string_stat, Queries),
          Query.define(:more_stats, Queries)
        ],
        data_attributes: %{
          "foo" => [title: "Just a date", order: 0],
          "var_1" => [title: "Var A", order: 1],
          "var_2" => [title: "Var B", order: 2]
        }
      ),
      Panel.define!(
        type: Panel.Chart,
        id: :multiple_time_series_with_diff,
        title: "Multiple Time Series with Ordering",
        queries: [Query.define(:multiple_time_series_with_diff, Queries)],
        ylabel: "Description",
        data_attributes: %{
          "a" => [type: :line, unit: "μCKR", order: 0],
          "b" => [type: :line, unit: "μFOO", order: 1],
          "a-b" => [type: :bar, order: 2]
        }
      ),
      Panel.define!(
        type: Panel.Chart,
        id: :multiple_time_series_with_stacking,
        title: "Multiple Time Series with Stacking",
        queries: [Query.define(:multiple_time_series_with_total, Queries)],
        ylabel: "Description",
        stacked_x: true,
        stacked_y: true,
        data_attributes: %{
          "a" => [type: :bar, order: 0],
          "b" => [type: :bar, order: 1],
          "total" => [fill: false]
        }
      )
    ],
    variables: [
      Variable.define!(id: :multiplier_var, label: "Multiplier", module: Variables),
      Variable.define!(id: :interval_var, label: "Interval", module: Variables),
      Variable.define!(
        id: :region_var,
        label: "Region",
        module: Variables,
        type: :multi,
        search: true
      )
    ]

  @impl Luminous.Dashboard
  def dashboard_path(socket, url_params), do: Routes.dashboard_path(socket, :index, url_params)

  @doc false
  # Here, we make use of the default component (`dashboard`) that
  # renders all the other components on screen
  # A live dashboard can also specify custom layouts by making use of
  # individual components from `Luminous.Components` or completely
  # custom components
  def render(assigns) do
    ~H"""
    <Components.dashboard dashboard={@dashboard} />
    """
  end
end
