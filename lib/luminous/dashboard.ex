defmodule Luminous.Dashboard do
  @moduledoc """
  A dashboard is the highest-level luminous component and contains all
  the necessary dashboard attributes such as the panels, variables and
  the time range selector. It also stores the state of the panels
  (query results). The dashboard is initialized in `Luminous.Live`
  and populated at runtime using `populate/2`.
  """

  alias Luminous.{Attributes, TimeRange, TimeRangeSelector, Variable}

  @type t :: map()

  @attributes [
    title: [type: :string, required: true],
    path: [type: {:fun, 3}, required: true],
    action: [type: :atom, required: true],
    panels: [type: {:list, :map}, default: []],
    variables: [type: {:list, :map}, default: []],
    time_range_selector: [type: {:struct, TimeRangeSelector}, default: %TimeRangeSelector{}],
    time_zone: [type: :string, default: TimeRange.default_time_zone()]
  ]

  @doc """
  Parse the supplied parameters and return the dashboard map structure.
  The following options are supported:
  #{NimbleOptions.docs(@attributes)}
  """
  @spec define!(keyword()) :: t()
  def define!(opts), do: Attributes.parse!(opts, @attributes)

  @doc """
  Populate the dashboard's dynamic properties (e.g. variable values, time range etc.) at runtime.
  """
  @spec populate(t(), map()) :: t()
  def populate(dashboard, socket_assigns) do
    dashboard
    |> Map.put(:data, %{})
    |> Map.put(:variables, Enum.map(dashboard.variables, &Variable.populate(&1, socket_assigns)))
    |> Map.put(
      :time_range_selector,
      TimeRangeSelector.new(dashboard.time_range_selector)
    )
  end

  @doc """
  Returns the LV path for the specific dashboard based on its configuration.
  The second argument can be either the socket or the Phoenix.Endpoint
  """
  @spec path(t(), Phoenix.LiveView.Socket.t() | module(), Keyword.t()) :: binary()
  def path(dashboard, socket_or_endpoint, params \\ []) do
    var_params =
      Enum.map(dashboard.variables, fn var ->
        {var.id, Keyword.get(params, var.id, Variable.extract_value(var.current))}
      end)

    time_range_params =
      params
      |> Keyword.get(:from)
      |> TimeRange.new(Keyword.get(params, :to))
      |> TimeRange.to_unix(get_current_time_range(dashboard))
      |> Keyword.new()

    dashboard.path.(
      socket_or_endpoint,
      dashboard.action,
      Keyword.merge(var_params, time_range_params)
    )
  end

  @doc """
  Update the dashboard's variables
  """
  @spec update_variables(t(), [Variable.t()]) :: t()
  def update_variables(dashboard, new_variables) do
    %{dashboard | variables: new_variables}
  end

  @doc """
  Update the dashboard's panel data
  """
  @spec update_data(t(), :atom, any()) :: t()
  def update_data(dashboard, panel_id, data), do: put_in(dashboard, [:data, panel_id], data)

  @doc """
  return the panel data for the specified panel
  """
  @spec get_data(t(), :atom) :: any()
  def get_data(dashboard, panel_id), do: get_in(dashboard, [:data, panel_id])

  @doc """
  Update the dashboard's current time range
  """
  @spec update_current_time_range(t(), TimeRange.t()) :: t()
  def update_current_time_range(dashboard, time_range) do
    %{
      dashboard
      | time_range_selector:
          TimeRangeSelector.update_current(dashboard.time_range_selector, time_range)
    }
  end

  @doc """
  Get the dashboard's current time range
  """
  @spec get_current_time_range(t()) :: TimeRange.t() | nil
  def get_current_time_range(dashboard),
    do: TimeRangeSelector.get_current(dashboard.time_range_selector)
end
