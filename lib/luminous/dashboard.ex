defmodule Luminous.Dashboard do
  @moduledoc """
  A dashboard is a high-level component initialized by the dashboard
  live view. It contains all the necessary dashboard attributes such as the
  panels, variables and the time range selector. It is initialized at
  compile time using `define/3` and populated at runtime using `populate/1`.
  """

  @doc """
  The dashboard uses a TimeRangeSelector and a default time range must be defined.
  """
  @callback default_time_range(binary()) :: Luminous.TimeRange.t()

  @doc """
  The consumer can optionally implement this callback, in case they want to
  inject custom parameters in other callbacks (e.g. `Luminous.Variable.variable/2`).
  Those parameters can be used to scope the callback results.
  """
  @callback parameters(Phoenix.LiveView.Socket.t()) :: map()

  @optional_callbacks parameters: 1

  alias Luminous.TimeRange
  alias Luminous.{Panel, TimeRange, TimeRangeSelector, Variable}

  @default_time_zone "Europe/Athens"

  @type t :: %__MODULE__{
          title: binary(),
          path: (... -> binary()),
          action: atom(),
          panels: [Panel.t()],
          variables: [Variable.t()],
          time_range_selector: TimeRangeSelector.t(),
          time_zone: binary()
        }

  @enforce_keys [:title, :path, :action, :panels, :variables, :time_range_selector]

  defstruct [
    :title,
    :path,
    :action,
    :panels,
    :variables,
    :time_range_selector,
    :time_zone
  ]

  @doc """
  Initialize and return a dashboard at compile time.
  """
  @spec define(binary(), {(... -> binary()), atom()}, Keyword.t()) :: t()
  def define(title, {path, action}, opts \\ []) do
    time_zone = Keyword.get(opts, :time_zone, @default_time_zone)

    %__MODULE__{
      title: title,
      path: path,
      action: action,
      time_range_selector: %TimeRangeSelector{},
      panels: Keyword.get(opts, :panels, []),
      variables: Keyword.get(opts, :variables, []),
      time_zone: time_zone
    }
  end

  @doc """
  Populate the dashboard's dynamic properties (e.g. variable values, time range etc.) at runtime.
  """
  @spec populate(t(), map()) :: t()
  def populate(dashboard, params) do
    dashboard
    |> Map.put(:variables, Enum.map(dashboard.variables, &Variable.populate(&1, params)))
    |> Map.put(
      :time_range_selector,
      TimeRangeSelector.populate(dashboard.time_range_selector, dashboard.time_zone)
    )
  end

  @doc """
  Returns the LV path for the specific dashboard based on its configuration.
  """
  @spec path(t(), Phoenix.LiveView.Socket.t(), Keyword.t()) :: binary()
  def path(dashboard, socket, params) do
    var_params =
      Enum.map(dashboard.variables, fn var ->
        {var.id, Keyword.get(params, var.id, var.current.value)}
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
