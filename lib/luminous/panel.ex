defmodule Luminous.Panel do
  @moduledoc """
  A panel represents a single visual element (chart) in a dashboard that can contain many queries.

  It also defines a behaviour that must be implemented by concrete Panels.
  """

  use Phoenix.Component

  alias Luminous.{Attributes, Dashboard, Query, TimeRange, Variable}
  alias Luminous.Query

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component

      @behaviour Luminous.Panel
    end
  end

  @type t :: map()

  @doc """
  transform a query result to view data acc. to the panel type
  """
  @callback transform(Query.result(), t()) :: any()

  @doc """
  aggregate all transformed results to a single structure
  that will be sent to the concrete panel
  """
  @callback reduce(list(), t(), Dashboard.t()) :: any()

  @doc """
  the phoenix function component that renders the panel
  see Luminous.Components.panel/1 for a description of the available assigns
  """
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  A list of the available panel actions that will be transmitted as events using JS.dispatch
  using the format panel:${panel_id}:${event}
  The `label` will be shown in the dropdown.
  This is an optional callback -- if undefined (or if it returns []), then the dropdown is not rendered
  """
  @callback actions() :: [%{event: binary(), label: binary()}]

  @optional_callbacks actions: 0

  @doc """
  Define custom attributes according to the panel type
  These will be used to parse, validate and populate the client's input
  """
  @callback panel_attributes() :: Attributes.Schema.t()

  @doc """
  Define the panel type's supported data attributes
  These will be used to parse, validate and populate the client's input
  """
  @callback data_attributes() :: Attributes.Schema.t()

  @doc """
  Define a panel
  Verifies all supplied options both generic (@attributes) and the concrete panel's attributes
  Will raise if the validation fails
  """
  @spec define!(Keyword.t()) :: t()
  def define!(opts \\ []) do
    mod = fetch_panel_module!(opts)
    schema = Attributes.Schema.panel() ++ apply(mod, :panel_attributes, [])

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
  @spec refresh(t(), [Variable.t()], TimeRange.t()) :: [any()]
  def refresh(panel, variables, time_range) do
    Enum.reduce(panel.queries, [], fn query, results ->
      # perform query
      result = Query.execute(query, time_range, variables)
      # transform result and add to results
      case apply(panel.type, :transform, [result, panel]) do
        data when is_list(data) -> results ++ data
        data -> [data | results]
      end
    end)
  end

  defp fetch_panel_module!(opts) do
    case Keyword.fetch(opts, :type) do
      {:ok, mod} -> mod
      :error -> raise "Please specify the :type argument with the desired panel module"
    end
  end

  defp validate_data_attributes!(panel) do
    schema = Attributes.Schema.data() ++ apply(panel.type, :data_attributes, [])

    panel.data_attributes
    |> Enum.map(fn {label, attrs} -> {label, Attributes.parse!(attrs, schema)} end)
    |> Map.new()
  end
end
