defmodule Luminous.Attributes do
  @moduledoc """
    Attributes map variable values (user-defined) to attribute keyword lists.
  """

  defmodule Data do
    @moduledoc """
    These are the data attributes that are common to all panel types
    """
    @attributes [
      title: [type: :string, default: ""],
      unit: [type: :string, default: ""],
      order: [type: :integer, default: 0]
    ]

    def common(), do: @attributes
  end

  @doc """
  Parse the supplied keyword list using the specified schema (performs validations as well)
  Return a map
  """
  @spec parse(keyword(), NimbleOptions.schema()) :: {:ok, map()} | {:error, binary()}
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
  @spec parse!(keyword(), NimbleOptions.schema()) :: map()
  def parse!(opts, schema) do
    case parse(opts, schema) do
      {:ok, attrs} -> attrs
      {:error, message} -> raise message
    end
  end
end
