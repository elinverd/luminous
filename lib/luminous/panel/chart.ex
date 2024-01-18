defmodule Luminous.Panel.Chart do
  alias Luminous.{Query, Panel}

  @behaviour Panel

  @impl true
  def supported_attributes(), do: [:type, :fill, :order]

  @impl true
  def transform(%Query.Result{rows: rows, attrs: attrs}) when is_list(rows) do
    # first, let's see if there's a specified ordering in var attrs
    order =
      Enum.reduce(attrs, %{}, fn {label, attrs}, acc ->
        Map.put(acc, label, attrs.order)
      end)

    rows
    |> extract_labels()
    |> Enum.map(fn label ->
      data =
        Enum.map(rows, fn row ->
          {x, y} =
            case row do
              # row is a list of {label, value} tuples
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

              # row is a map where labels map to values
              m when is_map(m) ->
                x =
                  case Map.get(row, :time) do
                    %DateTime{} = time -> DateTime.to_unix(time, :millisecond)
                    _ -> nil
                  end

                {x, Map.get(m, label)}

              # row is a single number
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
        Map.get(attrs, label) ||
          Map.get(attrs, to_string(label)) ||
          Panel.Attributes.new!(__MODULE__)

      %{
        rows: data,
        label: to_string(label),
        attrs: attrs,
        stats: statistics(data, to_string(label))
      }
    end)
    |> Enum.sort_by(fn dataset -> order[dataset.label] end)
  end

  def statistics(rows, label) do
    init_stats = %{n: 0, sum: nil, min: nil, max: nil, max_decimal_digits: 0}

    stats =
      Enum.reduce(rows, init_stats, fn %{y: y}, stats ->
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
    |> Map.put(:label, label)
    |> Map.delete(:max_decimal_digits)
  end

  defp convert_to_decimal(nil), do: nil

  defp convert_to_decimal(value) do
    case Decimal.cast(value) do
      {:ok, dec} -> dec
      _ -> value
    end
  end

  # example: [{:time, #DateTime<2022-10-01 01:00:00+00:00 UTC UTC>}, {"foo", #Decimal<0.65>}]
  defp extract_labels(rows) when is_list(rows) do
    rows
    |> Enum.flat_map(fn
      row ->
        row
        |> Enum.map(fn {label, _value} -> label end)
        |> Enum.reject(&(&1 == :time))
    end)
    |> Enum.uniq()
  end
end
