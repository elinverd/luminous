defmodule Luminous.Dashboard do
  @moduledoc """
  A dashboard is a high-level component initialized by the dashboard
  live view

  it contains all the necessary dashboard attributes such as the
  panels, variables and the time range selector

  it is initialized at compile time using define/4 and populated at
  runtime using populate/1
  """

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
  initialize a dashboard at compile time
  """
  @spec define(binary(), (... -> binary()), atom(), TimeRangeSelector.t(), Keyword.t()) :: t()
  def define(title, path, action, time_range_selector, opts \\ []) do
    %__MODULE__{
      title: title,
      path: path,
      action: action,
      time_range_selector: time_range_selector,
      panels: Keyword.get(opts, :panels, []),
      variables: Keyword.get(opts, :variables, []),
      time_zone: Keyword.get(opts, :time_zone, @default_time_zone)
    }
  end

  @doc """
  populate the dashboard's dynamic properties (e.g. variable values, time range etc.) at runtime
  """
  @spec populate(t()) :: t()
  def populate(dashboard) do
    dashboard
    |> Map.put(:variables, Enum.map(dashboard.variables, &Variable.populate/1))
    |> Map.put(
      :time_range_selector,
      TimeRangeSelector.populate(dashboard.time_range_selector, dashboard.time_zone)
    )
  end

  @doc """
  return the LV path for the specific dashboard based on its configuration
  """
  @spec path(t(), Phoenix.LiveView.Socket.t(), Keyword.t()) :: binary()
  def path(dashboard, socket, args), do: dashboard.path.(socket, dashboard.action, args)

  @doc """
  return the dashboard's default time range
  """
  @spec default_time_range(t()) :: TimeRange.t()
  def default_time_range(dashboard) do
    TimeRangeSelector.default_time_range(dashboard.time_range_selector, dashboard.time_zone)
  end

  @doc """
  update the dashboard's variables with a new list
  """
  @spec update_variables(t(), [Variable.t()]) :: t()
  def update_variables(dashboard, new_variables) do
    %{dashboard | variables: new_variables}
  end

  @doc """
  update the dashboard's current time range with a new one
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
