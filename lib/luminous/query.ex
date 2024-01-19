defmodule Luminous.Query do
  @moduledoc """
  A query is embedded in a panel and contains a function
  which will be executed upon panel refresh to fetch the query's data.
  """

  alias Luminous.{TimeRange, Variable}

  defmodule Result do
    @moduledoc """
    A query Result wraps a columnar data frame with multiple variables.
    `attrs` is a map where keys are variable labels (as specified
    in the query's select statement) and values are keyword lists with
    visualization properties.
    """
    @type label :: atom() | binary()
    @type value :: number() | Decimal.t() | binary() | nil
    @type point :: {label(), value()}
    @type row :: [point()]
    @type data :: [row()] | row() | map()
    @type t :: %__MODULE__{data: data()}

    @enforce_keys [:data]
    @derive Jason.Encoder
    defstruct [:data]

    @doc """
    This function can be called in the following ways:
    - with a list of points, i.e. a list of lists containing 2-tuples {label, value}
    - with a single row, i.e. a list of 2-tuples of the form {label, value} (e.g. in the case of single- or multi- stats)
    - with a
    - with a single value (for use in a single-valued stat panel with no label)
    """
    @spec new([data()] | data() | point() | value()) :: t()
    def new(data), do: %__MODULE__{data: data}
  end

  @doc """
  A module must implement this behaviour to be passed as an argument to `Luminous.Query.define/2`.
  A query must return a list of 2-tuples:
    - the 2-tuple's first element is the time series' label
    - the 2-tuple's second element is the label's value
  the list must contain a 2-tuple with the label `:time` and a `DateTime` value.
  """
  @callback query(atom(), TimeRange.t(), [Variable.t()]) :: Result.t()

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
  @spec execute(t(), TimeRange.t(), [Variable.t()]) :: Result.t()
  def execute(query, time_range, variables) do
    apply(query.mod, :query, [query.id, time_range, variables])
  end
end
