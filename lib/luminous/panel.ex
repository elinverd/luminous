defmodule Luminous.Panel do
  @moduledoc """
  A panel represents a single visual element (chart) in a dashboard
  Can contain many queries.
  """

  alias Luminous.Query
  alias Luminous.Panel.{Chart, Table, Stat}

  @type attributes :: map()

  @doc """
  transform a query result to view data acc. to the panel type
  """
  @callback transform(Query.Result.t()) :: any()
  @callback supported_attributes() :: [atom()]

  @panel_modules %{
    chart: Chart,
    stat: Stat,
    table: Table
  }

  @type panel_type :: :chart | :stat | :table
  defguard is_panel(type) when type in [:chart, :stat, :table]

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
          hook: binary(),
          y_min_value: number(),
          y_max_value: number()
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
    :stacked_y,
    :y_min_value,
    :y_max_value
  ]

  @doc """
  Initialize a panel at compile time.
  """
  @spec define(atom(), binary(), panel_type(), [Query.t()], Keyword.t()) :: t()
  def define(id, title, type, queries, opts \\ []) when is_panel(type) do
    %__MODULE__{
      id: id,
      title: title,
      type: type,
      queries: queries,
      unit: Keyword.get(opts, :unit, ""),
      description: Keyword.get(opts, :description),
      hook: Keyword.get(opts, :hook, default_panel_type(type)),
      ylabel: Keyword.get(opts, :ylabel),
      xlabel: Keyword.get(opts, :xlabel),
      stacked_x:
        if(Keyword.has_key?(opts, :stacked_x), do: Keyword.get(opts, :stacked_x), else: false),
      stacked_y:
        if(Keyword.has_key?(opts, :stacked_y), do: Keyword.get(opts, :stacked_y), else: false),
      y_min_value: Keyword.get(opts, :y_min_value),
      y_max_value: Keyword.get(opts, :y_max_value)
    }
  end

  @doc """
  Refresh all panel queries.
  """
  def refresh(panel, variables, time_range) do
    Enum.flat_map(panel.queries, fn query ->
      result = Query.execute(query, time_range, variables)

      apply(@panel_modules[panel.type], :transform, [result])
    end)
  end

  @doc """
  Returns the DOM id of the given panel.
  """
  @spec dom_id(t()) :: binary()
  def dom_id(%__MODULE__{} = panel), do: "panel-#{panel.id}"

  defp default_panel_type(:chart), do: "ChartJSHook"
  defp default_panel_type(:table), do: "TableHook"
  defp default_panel_type(_), do: nil
end
