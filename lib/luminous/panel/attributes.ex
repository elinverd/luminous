defmodule Luminous.Panel.Attributes do
  @moduledoc """
    Attributes map variable values (user-defined) to attribute keyword lists.

    Each panel type can define its own supported keyword arguments (through the @callback supported_attributes)

    There are also attributes that are common to all panels, defined in this module
  """

  @supported_attributes [:order, :unit, :title]

  defmodule NumberFormatting do
    @type t :: %__MODULE__{
            decimal_separator: binary(),
            thousand_separator: binary(),
            precision: non_neg_integer()
          }

    @derive Jason.Encoder
    defstruct [:decimal_separator, :thousand_separator, :precision]
  end

  @doc """
  Receives a mapping between (user-defined) variable names and their attributes (as keyword lists).
  Verifies that the keywords passed are valid acc. to the specified panel type
  """
  @spec new!(module(), %{any() => Keyword.t()}) :: %{any() => map()}
  def new!(panel_mod, attrs \\ %{}) when is_atom(panel_mod) and is_map(attrs) do
    attrs
    |> Enum.map(fn {label, kw_attrs} ->
      case validate(panel_mod, kw_attrs) do
        :ok -> {label, expand(panel_mod, kw_attrs)}
        {:error, message} -> raise "#{panel_mod}: #{message}"
      end
    end)
    |> Map.new()
  end

  @doc """
  Validates that the supplied attribute list conforms both to the panel type's and the common supported attributes
  """
  @spec validate(atom(), Keyword.t()) :: :ok | {:error, binary()}
  def validate(panel_mod, kw_attrs) do
    wl = whitelist(panel_mod)

    invalid_kw =
      kw_attrs
      |> Keyword.keys()
      |> Enum.find(&(&1 not in wl))

    if is_nil(invalid_kw) do
      :ok
    else
      {:error, "attribute #{invalid_kw} not supported"}
    end
  end

  @doc """
  Converts the attribute list to a map, adding the supported attributes that were not specified
  """
  @spec expand(atom(), Keyword.t()) :: map()
  def expand(panel_mod, kw_attrs) do
    panel_mod
    |> whitelist()
    |> Enum.reduce(Map.new(kw_attrs), fn lbl, acc ->
      Map.put_new(acc, lbl, nil)
    end)
  end

  @doc """
  returns all the supported attributes for the particular panel type (both panel-type-specific and common)
  """
  @spec whitelist(atom()) :: [atom()]
  def whitelist(panel_mod),
    do: apply(panel_mod, :supported_attributes, []) ++ @supported_attributes
end
