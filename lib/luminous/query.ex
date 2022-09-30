defmodule Luminous.Query do
  @moduledoc """
  a query is embedded in a panel and contains a function
  which will be executed upon panel refresh to fetch the query's data
  """
  alias Luminous.{TimeRange, Variable}

  defmodule DataSet do
    @moduledoc """
    a DataSet essentially wraps a list of 1-d or 2-d data points
    that has a label and a type (for visualization)
    """
    @type type :: :line | :bar
    @type row :: %{y: any()} | %{x: any(), y: any()}
    @type t :: %__MODULE__{
            rows: [row()],
            label: binary(),
            type: type(),
            fill: boolean()
          }

    @derive Jason.Encoder
    defstruct [:rows, :label, :type, :fill]

    @spec new([row()], atom() | binary(), Keyword.t()) :: t()
    def new(rows, label, opts \\ []) do
      %__MODULE__{
        rows: rows,
        label: to_string(label),
        type: Keyword.get(opts, :type) || :line,
        fill:
          if(Keyword.has_key?(opts, :fill),
            do: Keyword.get(opts, :fill),
            else: true
          )
      }
    end

    @doc """
    extract and return the first value out of rows
    e.g. for use in stat panels
    """
    @spec first_value(t()) :: nil | any()
    def first_value(%{rows: []}), do: nil

    def first_value(%{rows: rows}) do
      %{y: val} = hd(rows)
      val
    end

    @doc """
    calculate and return the basic statistics of the dataset in one pass (loop)
    """
    @spec statistics(t()) :: %{
            label: binary(),
            min: any(),
            max: any(),
            n: non_neg_integer(),
            sum: Decimal.t() | nil,
            avg: Decimal.t() | nil
          }
    def statistics(dataset) do
      init_stats = %{n: 0, sum: nil, min: nil, max: nil, max_decimal_digits: 0}

      stats =
        Enum.reduce(dataset.rows, init_stats, fn %{y: y}, stats ->
          y = unless is_nil(y), do: Decimal.new(y)
          min = Map.fetch!(stats, :min) || y
          max = Map.fetch!(stats, :max) || y
          sum = Map.fetch!(stats, :sum)
          n = Map.fetch!(stats, :n)
          max_decimal_digits = Map.fetch!(stats, :max_decimal_digits)

          new_sum =
            case {sum, y} do
              {nil, y} -> y
              {sum, nil} -> sum
              {sum, y} -> Decimal.add(y, sum)
            end

          decimal_digits =
            with y when not is_nil(y) <- y,
                 [_, dec] <- Decimal.to_string(y, :normal) |> String.split(".") do
              String.length(dec)
            else
              _ -> 0
            end

          stats
          |> Map.put(:min, if(!is_nil(y) && Decimal.lt?(y, min), do: y, else: min))
          |> Map.put(:max, if(!is_nil(y) && Decimal.gt?(y, max), do: y, else: max))
          |> Map.put(:sum, new_sum)
          |> Map.put(:n, if(is_nil(y), do: n, else: n + 1))
          |> Map.put(
            :max_decimal_digits,
            if(decimal_digits > max_decimal_digits, do: decimal_digits, else: max_decimal_digits)
          )
        end)

      # we use this to determine the rounding for the average dataset value
      max_decimal_digits = Map.fetch!(stats, :max_decimal_digits)

      # calculate the average
      avg =
        cond do
          stats[:n] == 0 ->
            nil

          is_nil(stats[:sum]) ->
            nil

          true ->
            Decimal.div(stats[:sum], Decimal.new(stats[:n])) |> Decimal.round(max_decimal_digits)
        end

      stats
      |> Map.put(:avg, avg)
      |> Map.put(:label, dataset.label)
      |> Map.delete(:max_decimal_digits)
    end
  end

  defmodule Result do
    @moduledoc """
    a query Result wraps a columnar data frame with multiple variables
    if time_series? is true then we expect to find :time in the row tuples

    `var_attrs` is a map where keys are variable labels (as specified
    in the query's select statement) and values are keyword lists with
    visualization properties for the corresponding Dataset. See
    Dataset.new/3 for details.
    """

    @type value :: any()
    @type row :: [{atom() | binary, value()}]
    @type t :: %__MODULE__{
            rows: row(),
            var_attrs: %{binary() => Keyword.t()},
            time_series?: boolean()
          }

    @enforce_keys [:rows, :var_attrs, :time_series?]
    defstruct [:rows, :var_attrs, :time_series?]

    @doc """
    new/2 can be called in 2 ways:
    - with a list of rows, i.e. a list of 2-tuples (label, value)
    - with a single value (for use in a single-valued stat panel) -- the label in this case is :value by default
    """
    @spec new([row()] | value(), Keyword.t()) :: t()
    def new(_, opts \\ [])

    def new(rows, opts) when is_list(rows) do
      %__MODULE__{
        rows: rows,
        var_attrs: Keyword.get(opts, :var_attrs, %{}),
        time_series?:
          if(Keyword.has_key?(opts, :time_series?),
            do: Keyword.get(opts, :time_series?),
            else: true
          )
      }
    end

    def new(value, opts) do
      %__MODULE__{
        rows: value,
        var_attrs: Keyword.get(opts, :var_attrs, %{}),
        time_series?: false
      }
    end

    @doc """
    transform the query Result (multiple variables as columns) to a list of Datasets
    timestamps are converted to unix time in milliseconds (js-compatible)
    """
    @spec transform(t()) :: [DataSet.t()]
    def transform(%__MODULE__{rows: rows} = result) when is_list(rows) do
      # first, let's see if there's a specified ordering in var attrs
      order =
        Enum.reduce(result.var_attrs, %{}, fn {label, attrs}, acc ->
          Map.put(acc, label, Keyword.get(attrs, :order))
        end)

      result.rows
      |> extract_labels()
      |> Enum.map(fn label ->
        data =
          Enum.map(result.rows, fn row ->
            # each key in a row can be either a string or an atom
            # in the case of a string we can't use Keyword.get/2
            Enum.find(row, fn {k, _v} -> k == label end)
            |> case do
              {^label, value} ->
                if result.time_series? do
                  time = Keyword.get(row, :time)

                  if is_nil(time),
                    do:
                      raise(
                        "Failed to transform query result: no `time` field in row. If this is not a time series, then `time_series?: false` needs to be passed to `Query.Result.new/2"
                      )

                  %{x: DateTime.to_unix(time, :millisecond), y: value}
                else
                  %{y: value}
                end

              nil ->
                nil
            end
          end)

        var_attrs =
          Map.get(result.var_attrs, label) ||
            Map.get(result.var_attrs, to_string(label)) ||
            []

        data
        |> Enum.reject(&is_nil/1)
        |> DataSet.new(label, var_attrs)
      end)
      |> Enum.sort_by(fn dataset -> order[dataset.label] end)
    end

    def transform(%__MODULE__{rows: value}), do: [DataSet.new([%{y: value}], nil)]

    defp extract_labels(rows) when is_list(rows) do
      rows
      |> Enum.flat_map(fn row ->
        row
        |> Enum.map(fn {label, _value} -> label end)
        |> Enum.reject(&(&1 == :time))
      end)
      |> Enum.uniq()
    end
  end

  @doc """
  a module must implement this behaviour to be passed
  as an argument to define/3
  a query must return a list of 2-tuples:
    - the 2-tuple's first element is the time series' label
    - the 2-tuple's second element is the label's value
  the list must contain a 2-tuple with the label `:time` and a `DateTime` value
  """
  @callback query(atom(), TimeRange.t(), [Variable.t()]) :: Result.t()

  @type t :: %__MODULE__{
          id: atom(),
          mod: module()
        }

  @enforce_keys [:id, :mod]
  defstruct [:id, :mod]

  @doc """
  initialize a query at compile time
  the module must implement the Query behaviour
  """
  @spec define(atom(), module()) :: t()
  def define(id, mod), do: %__MODULE__{id: id, mod: mod}

  @doc """
  execute the query and return the data as multiple TimeSeries structs
  """
  @spec execute(t(), TimeRange.t(), [Variable.t()]) :: Result.t()
  def(execute(query, time_range, variables)) do
    apply(query.mod, :query, [query.id, time_range, variables])
  end
end
