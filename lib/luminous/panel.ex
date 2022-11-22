defmodule Luminous.Panel do
  @moduledoc """
  A panel represents a single visual element (chart) in a dashboard
  contains many queries.
  """
  alias Luminous.{Query, Variable, TimeRange}

  @type panel_type :: :chart | :stat

  @type t :: %__MODULE__{
          id: atom(),
          title: binary(),
          description: binary(),
          type: panel_type(),
          queries: [Query.t()],
          unit: binary(),
          ylabel: binary(),
          xlabel: binary(),
          stacked_x: boolean(),
          stacked_y: boolean(),
          hook: binary()
        }

  @enforce_keys [:id, :title, :type, :queries, :hook]
  defstruct [
    :id,
    :title,
    :description,
    :type,
    :queries,
    :unit,
    :hook,
    :ylabel,
    :xlabel,
    :stacked_x,
    :stacked_y
  ]

  @doc """
  Initialize a panel at compile time.
  """
  @spec define(atom(), binary(), panel_type(), [Query.t()], Keyword.t()) :: t()
  def define(id, title, type, queries, opts \\ []) do
    %__MODULE__{
      id: id,
      title: title,
      type: type,
      queries: queries,
      unit: Keyword.get(opts, :unit, ""),
      description: Keyword.get(opts, :description),
      hook: Keyword.get(opts, :hook, "ChartJSHook"),
      ylabel: Keyword.get(opts, :ylabel),
      xlabel: Keyword.get(opts, :xlabel),
      stacked_x:
        if(Keyword.has_key?(opts, :stacked_x), do: Keyword.get(opts, :stacked_x), else: false),
      stacked_y:
        if(Keyword.has_key?(opts, :stacked_y), do: Keyword.get(opts, :stacked_y), else: false)
    }
  end

  @doc """
  Refresh all panel queries.
  """
  @spec refresh(t(), [Variable.t()], TimeRange.t()) :: [Query.DataSet.t()]
  def refresh(panel, variables, time_range) do
    Enum.flat_map(panel.queries, fn query ->
      query
      |> Query.execute(time_range, variables)
      |> Query.Result.transform()
    end)
  end

  @doc """
  Returns the DOM id of the given panel.
  """
  @spec dom_id(t()) :: binary()
  def dom_id(%__MODULE__{} = panel), do: "panel-#{panel.id}"
end
