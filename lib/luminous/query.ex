defmodule Luminous.Query do
  @moduledoc """
  a query is embedded in a panel and contains a function
  which will be executed upon panel refresh to fetch the query's data
  """
  alias Luminous.{TimeRange, Variable}

  defmodule Attributes do
    @moduledoc """
    This struct collects all the attributes that apply to a particular Dataset

    it is specified in the `attrs` argument of Query.result.new
    """
    @type t :: %__MODULE__{
            type: :line | :bar,
            order: non_neg_integer() | nil,
            fill: boolean(),
            unit: binary()
          }

    @derive Jason.Encoder
    defstruct [:type, :order, :fill, :unit]

    @spec define(Keyword.t()) :: t()
    def define(opts) do
      %__MODULE__{
        type: Keyword.get(opts, :type, :line),
        order: Keyword.get(opts, :order),
        fill:
          if(Keyword.has_key?(opts, :fill),
            do: Keyword.get(opts, :fill),
            else: true
          ),
        unit: Keyword.get(opts, :unit)
      }
    end

    @spec define() :: t()
    def define(), do: define([])
  end

  defmodule DataSet do
    @moduledoc """
    a DataSet essentially wraps a list of 1-d or 2-d data points
    that has a label and a type (for visualization)
    """
    @type type :: :line | :bar
    @type value :: Decimal.t() | binary()
    @type row :: %{y: value()} | %{x: any(), y: value()}
    @type t :: %__MODULE__{
            rows: [row()],
            label: binary(),
            attrs: Attributes.t()
          }

    @derive Jason.Encoder
    defstruct [:rows, :label, :attrs]

    @spec new([row()], atom() | binary(), Attributes.t() | nil) :: t()
    def new(rows, label, attrs \\ nil) do
      %__MODULE__{
        rows: rows,
        label: to_string(label),
        attrs: if(is_nil(attrs), do: Attributes.define(), else: attrs)
      }
    end

    @doc """
    extract and return the first value out of rows
    e.g. for use in stat panels
    """
    @spec first_value(t()) :: nil | any()
    def first_value(%{rows: []}), do: nil

    def first_value(%{rows: [%{y: val} | _]}), do: val

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

    @doc """
    override the dataset's unit with the provided string only if it's not already present
    """
    @spec maybe_override_unit(t(), binary()) :: t()
    def maybe_override_unit(%{attrs: %{unit: nil}} = dataset, unit) do
      attrs = Map.put(dataset.attrs, :unit, unit)
      Map.put(dataset, :attrs, attrs)
    end

    def maybe_override_unit(dataset, _), do: dataset
  end

  defmodule Result do
    @moduledoc """
    a query Result wraps a columnar data frame with multiple variables

    `attrs` is a map where keys are variable labels (as specified
    in the query's select statement) and values are keyword lists with
    visualization properties for the corresponding Dataset. See
    Dataset.new/3 for details.
    """
    @type label :: atom() | binary()
    @type value :: number() | Decimal.t() | binary()
    @type point :: {label(), value()}
    @type row :: [point()]
    @type t :: %__MODULE__{
            rows: row(),
            attrs: %{binary() => Attributes.t()}
          }

    @enforce_keys [:rows, :attrs]
    defstruct [:rows, :attrs]

    @doc """
    new/2 can be called in the following ways:
    - with a list of rows, i.e. a list of lists containing 2-tuples {label, value}
    - with a single row, i.e. a list of 2-tuples of the form {label, value} (e.g. in the case of single- or multi- stats)
    - with a single value (for use in a single-valued stat panel with no label)
    """
    @spec new([row()] | row() | point() | value(), Keyword.t()) :: t()
    def new(_, opts \\ [])

    def new(rows, opts) when is_list(rows) do
      %__MODULE__{
        rows: rows,
        attrs: Keyword.get(opts, :attrs, %{})
      }
    end

    def new({_, _} = row, opts), do: new([row], opts)

    def new(value, opts) do
      %__MODULE__{
        rows: value,
        attrs: Keyword.get(opts, :attrs, %{})
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
        Enum.reduce(result.attrs, %{}, fn {label, attrs}, acc ->
          Map.put(acc, label, attrs.order)
        end)

      result.rows
      |> extract_labels()
      |> Enum.map(fn label ->
        data =
          Enum.map(result.rows, fn row ->
            {x, y} =
              case row do
                # chart: row is a list of {label, value} tuples
                l when is_list(l) ->
                  x =
                    case Keyword.get(row, :time) do
                      %DateTime{} = time -> DateTime.to_unix(time, :millisecond)
                      _ -> nil
                    end

                  y =
                    Enum.find_value(l, fn
                      {^label, value} -> value
                      _ -> nil
                    end)

                  {x, y}

                # stat: row is a single {label, value} tuple
                {^label, value} ->
                  {nil, value}

                # stat: row is a single {label, value} tuple but we are processing a different label
                {_, _} ->
                  {nil, nil}

                # stat: row is a single number
                n when is_number(n) ->
                  {nil, n}

                _ ->
                  raise "Can not process data row #{inspect(row)}"
              end

            case {x, y} do
              {nil, y} -> %{y: convert_to_decimal(y)}
              {x, y} -> %{x: x, y: convert_to_decimal(y)}
            end
          end)
          |> Enum.reject(&is_nil(&1.y))

        attrs =
          Map.get(result.attrs, label) ||
            Map.get(result.attrs, to_string(label)) ||
            Attributes.define()

        DataSet.new(data, label, attrs)
      end)
      |> Enum.sort_by(fn dataset -> order[dataset.label] end)
    end

    def transform(%__MODULE__{rows: value}),
      do: [DataSet.new([%{y: convert_to_decimal(value)}], nil, Attributes.define())]

    defp extract_labels(rows) when is_list(rows) do
      rows
      |> Enum.flat_map(fn
        # example: [{:time, #DateTime<2022-10-01 01:00:00+00:00 UTC UTC>}, {"foo", #Decimal<0.65>}]
        row when is_list(row) ->
          row
          |> Enum.map(fn {label, _value} -> label end)
          |> Enum.reject(&(&1 == :time))

        # example: {:single_stat, #Decimal<0.65>}
        {label, _} ->
          [label]
      end)
      |> Enum.uniq()
    end

    defp convert_to_decimal(nil), do: nil

    defp convert_to_decimal(value) do
      case Decimal.cast(value) do
        {:ok, dec} -> dec
        _ -> value
      end
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
