defmodule Luminous.Attributes do
  @moduledoc """
  Attributes map variable values (user-defined) to attribute keyword lists.
  They are created by parsing and validating a NimbleOptions schema (see parse/2).
  """
  @type t :: map()

  defmodule Schema do
    @moduledoc """
    Attribute schemas that are common across all instances of their type.
    """
    alias Luminous.Query

    @type t :: NimbleOptions.schema()

    @doc """
    Schema for the attributes that apply to all panels regardless of their type
    """
    @spec panel() :: t()
    def panel(),
      do: [
        type: [type: :atom, required: true],
        id: [type: :atom, required: true],
        title: [type: :string, default: ""],
        queries: [type: {:list, {:struct, Query}}],
        description: [type: {:or, [:string, nil]}, default: nil],
        attributes: [type: :keyword_list, default: []],
        data_attributes: [type: {:map, {:or, [:atom, :string]}, :keyword_list}, default: %{}]
      ]

    @doc """
    Schema for the attributes that apply to all data attributes
    regardless of the Panel in which they are defined
    """
    @spec data() :: t()
    def data(),
      do: [
        title: [type: :string, default: ""],
        unit: [type: :string, default: ""],
        order: [type: :integer, default: 0]
      ]
  end

  @doc """
  Parse the supplied keyword list using the specified schema (performs validations as well)
  Return a map
  """
  @spec parse(keyword(), Schema.t()) :: {:ok, t()} | {:error, binary()}
  def parse(opts, schema) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, attrs} -> {:ok, Map.new(attrs)}
      {:error, %{message: message}} -> {:error, message}
    end
  end

  @doc """
  parse the supplied keyword list using the specified schema (performs validations as well)
  return a map or raise on error
  """
  @spec parse!(keyword(), Schema.t()) :: map()
  def parse!(opts, schema) do
    case parse(opts, schema) do
      {:ok, attrs} -> attrs
      {:error, message} -> raise message
    end
  end
end
