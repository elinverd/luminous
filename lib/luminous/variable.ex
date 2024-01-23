defmodule Luminous.Variable do
  @moduledoc """
  A variable is defined at compile time and its values are determined at runtime.
  It also stores a current value that can be updated. A variable value is
  descriptive in that it contains a label (for display purposes) and the actual value.
  """
  alias Luminous.Attributes

  @doc """
  A module must implement this behaviour to be passed as an argument to `define/3`.
  """
  @callback variable(atom(), map()) :: [simple_value() | descriptive_value()]

  @type t :: map()

  @type simple_value :: binary()
  @type descriptive_value :: %{label: binary(), value: binary()}

  @attributes [
    id: [type: :atom, required: true],
    label: [type: :string, required: true],
    module: [type: :atom, required: true],
    type: [type: {:in, [:single, :multi]}, default: :single]
  ]

  @doc """
  Defines a new variable and returns a map
  """
  @spec define!(keyword()) :: t()
  def define!(opts \\ []) do
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
  Uses the query to populate the variables's values and returns the new struct.
  Additionally, it sets the current value to be the first of the calculated values.
  """
  @spec populate(t(), map()) :: t()
  def populate(var, params) do
    values =
      var.module
      |> apply(:variable, [var.id, params])
      |> Enum.map(fn
        m when is_map(m) -> m
        s when is_binary(s) -> %{label: s, value: s}
      end)

    var
    |> Map.put(:values, values)
    |> Map.put(:current, List.first(values))
  end

  @doc """
  Returns the variable's current (descriptive) value or `nil`.
  """
  @spec get_current(t()) :: descriptive_value() | nil
  def get_current(nil), do: nil
  def get_current(%{current: value}), do: value

  @doc """
  Find the variable with the supplied `id` in the supplied variables
  and return its current extracted value.
  """
  @spec get_current_and_extract_value([t()], atom()) :: binary()
  def get_current_and_extract_value(variables, variable_id) do
    variables
    |> find(variable_id)
    |> get_current()
    |> extract_value()
  end

  @doc """
  Extracts and returns the label from the descriptive variable value.
  """
  @spec extract_label(descriptive_value()) :: binary()
  def extract_label(nil), do: nil
  def extract_label(%{label: label}), do: label

  @doc """
  Extract and returns the value from the descriptive variable value.
  """
  @spec extract_value(descriptive_value()) :: binary()
  def extract_value(nil), do: nil
  def extract_value(%{value: value}), do: value

  @doc """
  Replaces the variables current value with the new value and returns the new struct.
  It performs a check whether the supplied value is a valid value (i.e. exists in values).
  If it's not, then it returns the struct unchanged.
  """
  @spec update_current(t(), binary()) :: t()
  def update_current(var, new_value) when is_binary(new_value) do
    new_val = Enum.find(var.values, fn val -> val.value == new_value end)

    if is_nil(new_val), do: var, else: %{var | current: new_val}
  end
end
