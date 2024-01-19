defmodule Luminous.Panel.Attributes do
  @moduledoc """
    Attributes map variable values (user-defined) to attribute keyword lists.

    Each panel type can define its own supported keyword arguments (through the @callback supported_attributes)

    There are also attributes that are common to all panels, defined in this module
  """

  defmodule Data do
    @attributes [
      title: [type: :string, default: ""],
      unit: [type: :string, default: ""],
      order: [type: :integer, default: 0]
    ]

    def common(), do: @attributes
  end

  @spec parse(keyword(), NimbleOptions.schema()) :: {:ok, map()} | {:error, binary()}
  def parse(opts, schema) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, attrs} -> {:ok, Map.new(attrs)}
      {:error, %{message: message}} -> {:error, message}
    end
  end

  @spec parse!(keyword(), NimbleOptions.schema()) :: map()
  def parse!(opts, schema) do
    case parse(opts, schema) do
      {:ok, attrs} -> attrs
      {:error, message} -> raise message
    end
  end
end
