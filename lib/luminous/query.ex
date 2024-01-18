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
    @type row :: [point()] | map()
    @type t :: %__MODULE__{
            rows: row(),
            attrs: map()
          }

    @enforce_keys [:rows, :attrs]
    @derive Jason.Encoder
    defstruct [:rows, :attrs]

    @doc """
    This function can be called in the following ways:
    - with a list of rows, i.e. a list of lists containing 2-tuples {label, value}
    - with a single row, i.e. a list of 2-tuples of the form {label, value} (e.g. in the case of single- or multi- stats)
    - with a single value (for use in a single-valued stat panel with no label)
    """
    @spec new([row()] | row() | point() | value(), map()) :: t()
    def new(_, attrs \\ %{})

    def new(rows, attrs) when is_list(rows) do
      %__MODULE__{
        rows: rows,
        attrs: attrs
      }
    end

    def new({_, _} = row, attrs), do: new([row], attrs)

    def new(value, attrs) do
      %__MODULE__{
        rows: value,
        attrs: attrs
      }
    end
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
