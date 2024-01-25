defmodule Luminous.Query do
  @moduledoc """
  A query is embedded in a panel and contains a function
  which will be executed upon panel refresh to fetch the query's data.
  """

  alias Luminous.{TimeRange, Variable}

  @type result :: any()

  @doc """
  A module must implement this behaviour to be passed as an argument to `define/2`.
  A query must return a list of 2-tuples:
    - the 2-tuple's first element is the time series' label
    - the 2-tuple's second element is the label's value
  the list must contain a 2-tuple with the label `:time` and a `DateTime` value.
  """
  @callback query(atom(), TimeRange.t(), [Variable.t()]) :: result()

  @type t :: %__MODULE__{
          id: atom(),
          mod: module()
        }

  @enforce_keys [:id, :mod]
  defstruct [:id, :mod]

  @doc """
  Initialize a query at compile time. The module must implement the `Luminous.Query` behaviour.
  """
  @spec define(atom(), module()) :: t()
  def define(id, mod), do: %__MODULE__{id: id, mod: mod}

  @doc """
  Execute the query and return the data as multiple TimeSeries structs.
  """
  @spec execute(t(), TimeRange.t(), [Variable.t()]) :: result()
  def execute(query, time_range, variables) do
    apply(query.mod, :query, [query.id, time_range, variables])
  end
end
