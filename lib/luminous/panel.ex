defmodule Luminous.Panel do
  @moduledoc """
  A panel represents a single visual element (chart) in a dashboard
  that can contain many queries. A panel is "refreshed" when the live
  view first loads, as well as when a variable or the time range are
  updated. The panel's data (as returned by the queries) are stored in
  `Luminous.Dashboard`.

  The module defines a behaviour that must be implemented by concrete
  panels either inside Luminous (e.g. `Luminous.Panel.Chart`,
  `Luminous.Panel.Stat` etc.) or on the client side.

  When a Panel is refreshed (`refresh/3`), the execution flow is as follows:

  - for each query:
    - execute the query (`Luminous.Query.execute()`)
    - `transform/2` the query result
  - `reduce/3` (aggregate) the transformed query results
  """

  use Phoenix.Component

  alias Luminous.{Attributes, Dashboard, Query, TimeRange, Variable}

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
  aggregate all transformed results to a single map
  that will be sent for visualization
  """
  @callback reduce(list(), t(), Dashboard.t()) :: map()

  @doc """
  The phoenix function component that renders the panel. The panel's
  title, description tooltip, contextual menu etc. are rendered
  elsewhere. See `Luminous.Components.panel/1` for a description of the available assigns.
  """
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  A list of the available panel actions that will be transmitted as events using JS.dispatch
  using the format "panel:${panel_id}:${event}"
  The `label` will be shown in the dropdown.
  This is an optional callback -- if undefined (or if it returns []), then the dropdown is not rendered
  """
  @callback actions() :: [%{event: binary(), label: binary()}]

  @doc """
  Define custom attributes specific to the concrete panel type
  These will be used to parse, validate and populate the client's input
  """
  @callback panel_attributes() :: Attributes.Schema.t()

  @doc """
  Define the panel type's supported data attributes
  These will be used to parse, validate and populate the client's input
  """
  @callback data_attributes() :: Attributes.Schema.t()

  @optional_callbacks panel_attributes: 0, data_attributes: 0, actions: 0

  @doc """

  Initialize a panel. Verifies all supplied options both generic
  and the concrete panel's attributes.  Will raise if
  the validation fails. The supported generic attributes are:

  #{NimbleOptions.docs(Attributes.Schema.panel())}

  """
  @spec define!(Keyword.t()) :: t()
  def define!(opts \\ []) do
    mod = fetch_panel_module!(opts)
    schema = Attributes.Schema.panel() ++ get_attributes!(mod, :panel_attributes)

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
    schema = Attributes.Schema.data() ++ get_attributes!(panel.type, :data_attributes)

    panel.data_attributes
    |> Enum.map(fn {label, attrs} -> {label, Attributes.parse!(attrs, schema)} end)
    |> Map.new()
  end

  defp get_attributes!(panel_type, attribute_type) do
    # first, we need to ensure that the module `panel_type` is loaded
    # because if it isn't then function_exported?/3 will return false
    # even if the module is defined
    panel_type =
      case Code.ensure_loaded(panel_type) do
        {:module, mod} -> mod
        {:error, reason} -> raise "failed to load module #{panel_type}: #{reason}"
      end

    if function_exported?(panel_type, attribute_type, 0) do
      apply(panel_type, attribute_type, [])
    else
      []
    end
  end
end
