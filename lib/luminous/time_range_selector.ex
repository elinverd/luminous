defmodule Luminous.TimeRangeSelector do
  @moduledoc """
  A selector supports the widget in the dashboard that allows
  for selecting a time range/period.
  It can also be updated with a new value.
  """
  alias Luminous.TimeRange

  @type preset :: binary()

  @type t :: %__MODULE__{current_time_range: nil | TimeRange.t()}

  defstruct [:id, :current_time_range]

  @presets [
    {"Today", &TimeRange.today/1, []},
    {"Yesterday", &TimeRange.yesterday/1, []},
    {"Last 7 days", &TimeRange.last_n_days/2, [7]},
    {"This week", &TimeRange.this_week/1, []},
    {"Previous week", &TimeRange.last_week/1, []},
    {"This month", &TimeRange.this_month/1, []},
    {"Previous month", &TimeRange.last_month/1, []}
  ]

  def id(), do: "time-range-selector"

  def hook(), do: "TimeRangeHook"

  @doc """
  Create and return a new selector
  """
  @spec new(t()) :: t()
  def new(selector), do: Map.put(selector, :id, id())

  @doc """
  Updates the current time range of the selector.
  """
  @spec update_current(t(), TimeRange.t()) :: t()
  def update_current(selector, time_range) do
    Map.put(selector, :current_time_range, time_range)
  end

  @doc """
  Get the selector's current time range value
  """
  @spec get_current(t()) :: TimeRange.t() | nil
  def get_current(selector), do: selector.current_time_range

  @doc """
  Returns a list with the available time range presets.
  """
  @spec presets() :: [preset()]
  def presets(), do: ["Default" | Enum.map(@presets, fn {label, _, _} -> label end)]

  @doc """
  Calculates and returns the time range for the given preset in the given
  time zone.
  """
  @spec get_time_range_for(preset(), TimeRange.time_zone()) :: TimeRange.t() | nil
  def get_time_range_for(preset, time_zone) do
    case Enum.find(@presets, fn {label, _, _} -> label == preset end) do
      {_, function, args} -> apply(function, List.insert_at(args, -1, time_zone))
      _ -> nil
    end
  end
end
