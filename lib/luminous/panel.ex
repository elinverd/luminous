defmodule Luminous.Panel do
  @moduledoc """
  A panel represents a single visual element (chart) in a dashboard that can contain many queries.
  """

  alias Luminous.{Attributes, Query, TimeRange, Variable}
  alias Luminous.Query
  alias Luminous.Panel.{Chart, Table, Stat}

  @type t :: map()

  @doc """
  transform a query result to view data acc. to the panel type
  """
  @callback transform(Query.Result.t(), t()) :: any()

  @doc """
  Define custom attributes according to the panel type
  These will be used to parse, validate and populate the client's input
  """
  @callback panel_attributes() :: NimbleOptions.schema()

  @doc """
  Define the panel type's supported data attributes
  These will be used to parse, validate and populate the client's input
  """
  @callback data_attributes() :: NimbleOptions.schema()

  # this attribute list applies to all panels
  @attributes [
    type: [type: {:in, [Chart, Stat, Table]}, required: true],
    id: [type: :atom, required: true],
    title: [type: :string, default: ""],
    queries: [type: {:list, {:struct, Query}}],
    description: [type: {:or, [:string, nil]}, default: nil],
    attributes: [type: :keyword_list, default: []],
    data_attributes: [type: {:map, {:or, [:atom, :string]}, :keyword_list}, default: %{}]
  ]

  @doc """
  Define a panel
  Verifies all supplied options both generic (@attributes) and the concrete panel's attributes
  Will raise if the validation fails
  """
  @spec define!(Keyword.t()) :: t()
  def define!(opts \\ []) do
    mod = fetch_panel_module!(opts)
    schema = @attributes ++ apply(mod, :panel_attributes, [])

    case Attributes.parse(opts, schema) do
      {:ok, panel} ->
        Map.put(panel, :data_attributes, validate_data_attributes!(panel))

      {:error, message} ->
        raise message
    end
  end

  @doc """
  Refresh all panel queries.
  """
  @spec refresh(t(), [Variable.t()], TimeRange.t()) :: any()
  def refresh(panel, variables, time_range) do
    Enum.flat_map(panel.queries, fn query ->
      result = Query.execute(query, time_range, variables)

      apply(panel.type, :transform, [result, panel])
    end)
  end

  defp fetch_panel_module!(opts) do
    case Keyword.fetch(opts, :type) do
      {:ok, mod} -> mod
      :error -> raise "Please specify the :type argument with the desired panel module"
    end
  end

  defp validate_data_attributes!(panel) do
    schema = Attributes.Data.common() ++ apply(panel.type, :data_attributes, [])

    panel.data_attributes
    |> Enum.map(fn {label, attrs} -> {label, Attributes.parse!(attrs, schema)} end)
    |> Map.new()
  end
end
