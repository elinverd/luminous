defmodule Luminous.Variable do
  @moduledoc """
  A variable is defined inside a Dashboard and its values are
  determined at runtime. The variable also stores a current value
  that can be updated. A variable value can be simple (just a value)
  or descriptive in that it contains a label (for display purposes)
  and the actual value.

  Variables are visualized as dropdowns in the dashboard view.

  There are two Variable types:
  - `single`: only one value can be selected by the user (default type)
  - `multi`: multiple values can be selected by the user

  A Variable can also be hidden in which case:
  - it will not be rendered as a dropdown in the dashboard
  - it will not be included in the URL params

  Hidden variables are a means for keeping some kind of state for
  framework clients. A typical use case is implementing custom panels
  which need some state (e.g. pagination).
  """

  alias Luminous.Attributes

  @doc """
  A module must implement this behaviour to be passed as an argument to `define!/1`.
  The function receives the variable id and the LV socket assigns.
  """
  @callback variable(atom(), map()) :: [simple_value() | descriptive_value()]

  @type t :: map()

  @type simple_value :: binary()
  @type descriptive_value :: %{label: binary(), value: binary()}

  @attributes [
    id: [type: :atom, required: true],
    label: [type: :string, required: true],
    module: [type: :atom, required: true],
    type: [type: {:in, [:single, :multi]}, default: :single],
    multi_default: [type: {:in, [:all, :none]}, default: :all],
    search: [type: :boolean, default: false],
    hidden: [type: :boolean, default: false]
  ]

  @doc """
  Defines a new variable and returns a map. The following options can be passed:
  #{NimbleOptions.docs(@attributes)}
  """
  @spec define!(keyword()) :: t()
  def define!(opts) do
    variable = Attributes.parse!(opts, @attributes)

    if variable.id in [:from, :to] do
      raise ":from and :to are reserved atoms in luminous and can not be used as variable IDs"
    end

    variable
  end

  @doc """
  Find and return the variable with the specified id in the supplied variables.
  """
  @spec find([t()], atom()) :: t() | nil
  def find(variables, id), do: Enum.find(variables, fn v -> v.id == id end)

  @doc """
  Uses the callback to populate the variables's values and returns the
  updated variable. Additionally, it sets the current value to be the
  first of the available values in the case of a single variable or
  all of the available values in the case of a multi variable.
  """
  @spec populate(t(), map()) :: t()
  def populate(var, socket_assigns) do
    values =
      var.module
      |> apply(:variable, [var.id, socket_assigns])
      |> Enum.map(fn
        m when is_map(m) -> m
        s when is_binary(s) -> %{label: s, value: s}
      end)

    case var.type do
      :single ->
        var
        |> Map.put(:values, values)
        |> Map.put(:current, List.first(values))

      :multi ->
        current =
          case var.multi_default do
            :all -> values
            :none -> []
          end

        var
        |> Map.put(:values, values)
        |> Map.put(:current, current)
    end
  end

  @doc """
  Returns the variable's current (descriptive) value(s) or `nil`.
  """
  @spec get_current(t()) :: descriptive_value() | [descriptive_value()] | nil
  def get_current(nil), do: nil
  def get_current(%{current: value}), do: value

  @doc """
  Find the variable with the supplied `id` in the supplied variables
  and return its current extracted value.
  """
  @spec get_current_and_extract_value([t()], atom()) :: binary() | [binary()] | nil
  def get_current_and_extract_value(variables, variable_id) do
    variables
    |> find(variable_id)
    |> get_current()
    |> extract_value()
  end

  @doc """
  Returns the label based on the variable type and current value selection
  """
  @spec get_current_label(t()) :: binary() | nil
  def get_current_label(%{current: nil}), do: nil
  def get_current_label(%{current: %{label: label}}), do: label

  def get_current_label(%{current: []}), do: "None"
  def get_current_label(%{current: [value]}), do: value.label

  def get_current_label(%{current: current} = var) when is_list(current) do
    if length(current) == length(var.values) do
      "All"
    else
      "#{length(current)} selected"
    end
  end

  @doc """
  Extract and return the value from the descriptive variable value.
  """
  @spec extract_value(descriptive_value()) :: binary() | [binary()] | nil
  def extract_value(nil), do: nil
  def extract_value(%{value: value}), do: value
  def extract_value(values) when is_list(values), do: Enum.map(values, & &1.value)

  @doc """
  Replaces the variables current value with the new value and returns the map.
  It performs a check whether the supplied value is a valid value (i.e. exists in values).
  If it's not, then it returns the map unchanged.
  The special "none" case is for when the variable's type is :multi and none of the
  values are selected (empty list)
  """
  @spec update_current(t(), nil | binary() | [binary()], map()) :: t()
  def update_current(var, nil, assigns), do: populate(var, assigns)
  def update_current(%{type: :multi} = var, "none", _), do: %{var | current: []}

  def update_current(%{hidden: hidden} = var, new_value, _) when is_binary(new_value) do
    new_val =
      if hidden do
        %{value: new_value, label: new_value}
      else
        Enum.find(var.values, fn val -> val.value == new_value end)
      end

    if is_nil(new_val), do: var, else: %{var | current: new_val}
  end

  def update_current(%{hidden: hidden} = var, new_values, _) when is_list(new_values) do
    legitimate_values = Enum.filter(var.values, fn %{value: value} -> value in new_values end)

    new_values =
      if hidden do
        Enum.map(new_values, fn v -> %{label: v, value: v} end)
      else
        if length(new_values) == length(legitimate_values) do
          legitimate_values
        else
          var.current
        end
      end

    %{var | current: new_values}
  end

  @doc """
  Returns true if the variable was declared to include a search field for the listed items,
  otherwise false.
  """
  @spec show_search?(t()) :: boolean()
  def show_search?(%{search: value}), do: value
end
