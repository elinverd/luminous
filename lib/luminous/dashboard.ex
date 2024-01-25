defmodule Luminous.Dashboard do
  @moduledoc """
  A dashboard is the highest-level Luminous component initialized by
  the dashboard live view. It contains all the necessary dashboard
  attributes such as the panels, variables and the time range
  selector. It is initialized by `use Luminous.Live` and populated at
  runtime using `populate/1`.
  """

  alias Luminous.{Attributes, TimeRange, TimeRangeSelector, Variable}

  @doc """
  The dashboard uses a TimeRangeSelector and a default time range must be defined.
  """
  @callback default_time_range(binary()) :: TimeRange.t()

  @doc """
  The consumer can optionally implement this callback, in case they want to
  inject custom parameters in other callbacks (e.g. `Luminous.Variable` behaviour).
  Those parameters can be used to scope the callback results.
  """
  @callback parameters(Phoenix.LiveView.Socket.t()) :: map()

  @optional_callbacks parameters: 1

  @default_time_zone "Europe/Athens"

  @type t :: map()

  @attributes [
    title: [type: :string, required: true],
    path: [type: {:fun, 3}, required: true],
    action: [type: :atom, required: true],
    panels: [type: {:list, :map}, default: []],
    variables: [type: {:list, :map}, default: []],
    time_range_selector: [type: {:struct, TimeRangeSelector}, default: %TimeRangeSelector{}],
    time_zone: [type: :string, default: @default_time_zone]
  ]

  @doc """
  Parse the supplied parameters according to the @attributes schema
  and return the dashboard map structure
  """
  @spec define!(keyword()) :: t()
  def define!(opts), do: Attributes.parse!(opts, @attributes)

  @doc """
  Populate the dashboard's dynamic properties (e.g. variable values, time range etc.) at runtime.
  """
  @spec populate(t(), map()) :: t()
  def populate(dashboard, params) do
    dashboard
    |> Map.put(:data, %{})
    |> Map.put(:variables, Enum.map(dashboard.variables, &Variable.populate(&1, params)))
    |> Map.put(
      :time_range_selector,
      TimeRangeSelector.new(dashboard.time_range_selector)
    )
  end

  @doc """
  Returns the LV path for the specific dashboard based on its configuration.
  """
  @spec path(t(), Phoenix.LiveView.Socket.t(), Keyword.t()) :: binary()
  def path(dashboard, socket, params) do
    var_params =
      Enum.map(dashboard.variables, fn var ->
        {var.id, Keyword.get(params, var.id, Variable.extract_value(var.current))}
      end)

    time_range_params = [
      from:
        params
        |> Keyword.get(:from, dashboard.time_range_selector.current_time_range.from)
        |> DateTime.to_unix(),
      to:
        params
        |> Keyword.get(:to, dashboard.time_range_selector.current_time_range.to)
        |> DateTime.to_unix()
    ]

    dashboard.path.(socket, dashboard.action, Keyword.merge(var_params, time_range_params))
  end

  @doc """
  Update the dashboard's variables with a new list.
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
  Update the dashboard's current time range with a new one.
  """
  @spec update_current_time_range(t(), TimeRange.t()) :: t()
  def update_current_time_range(dashboard, time_range) do
    %{
      dashboard
      | time_range_selector:
          TimeRangeSelector.update_current(dashboard.time_range_selector, time_range)
    }
  end
end
