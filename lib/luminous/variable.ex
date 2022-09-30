defmodule Luminous.Variable do
  @moduledoc """
  a variable is defined at compile time
  and its values are determined at runtime

  it also stores a current value that can be updated

  a variable value is descriptive in that it contains
  a label (for display purposes) and the actual value
  """

  @doc """
  a module must implement this behaviour to be passed
  as an argument to define/3
  """
  @callback variable(atom()) :: [simple_value() | descriptive_value()]

  @type simple_value :: binary()
  @type descriptive_value :: %{label: binary(), value: binary()}

  @type t :: %__MODULE__{
          id: atom(),
          label: binary(),
          mod: module(),
          values: [descriptive_value()],
          current: descriptive_value() | nil
        }
  @enforce_keys [:id, :label, :mod]
  defstruct [:id, :label, :mod, :values, :current]

  @doc """
  find and return the variable with the specified id
  in the supplied variables
  """
  @spec find([t()], atom()) :: t() | nil
  def find(variables, id), do: Enum.find(variables, fn v -> v.id == id end)

  @doc """
  defines a new variable and returns the struct
  does not calculate the values yet (see populate/1 below)
  the module must implement the Variable behaviour
  """
  @spec define(atom(), binary(), module()) :: t()
  def define(id, label, mod) do
    %__MODULE__{
      id: id,
      label: label,
      mod: mod,
      values: [],
      current: nil
    }
  end

  @doc """
  uses the query to populate the var's values and returns the new struct
  also sets the current value to be the first of the calculated values
  """
  @spec populate(t()) :: t()
  def populate(var) do
    values =
      var.mod
      |> apply(:variable, [var.id])
      |> Enum.map(fn
        m when is_map(m) -> m
        s when is_binary(s) -> %{label: s, value: s}
      end)

    %{var | values: values, current: List.first(values)}
  end

  @doc """
  returns the variable's current (descriptive) value (or nil)
  """
  @spec get_current(t()) :: descriptive_value() | nil
  def get_current(nil), do: nil
  def get_current(%{current: value}), do: value

  @doc """
  find the variable with the supplied id in the supplied variables
  and return its current extracted value
  """
  @spec get_current_and_extract_value([t()], atom()) :: binary()
  def get_current_and_extract_value(variables, variable_id) do
    variables
    |> find(variable_id)
    |> get_current()
    |> extract_value()
  end

  @doc """
  extract the label from the descriptive variable value
  """
  @spec extract_label(descriptive_value()) :: binary()
  def extract_label(nil), do: nil
  def extract_label(%{label: label}), do: label

  @doc """
  extract the value from the descriptive variable value
  """
  @spec extract_value(descriptive_value()) :: binary()
  def extract_value(nil), do: nil
  def extract_value(%{value: value}), do: value

  @doc """
  replaces the variables current value with the new value and returns the new struct
  performs a check whether the supplied value is a valid value (i.e. exists in values)
  if it's not, then it returns the struct unchanged
  """
  @spec update_current(t(), binary()) :: t()
  def update_current(var, new_value) when is_binary(new_value) do
    new_val = Enum.find(var.values, fn val -> val.value == new_value end)

    if is_nil(new_val), do: var, else: %{var | current: new_val}
  end
end
