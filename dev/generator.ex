defmodule Luminous.Generator do
  @spec generate(Luminous.TimeRange.t(), non_neg_integer(), :hour | :day, binary() | [binary()]) ::
          [
            Luminous.Query.Result.row()
          ]
  def generate(time_range, multiplier, interval, variables) when is_list(variables) do
    time_range
    |> generate_time_points(interval)
    |> Enum.map(fn t ->
      row =
        Enum.reduce(variables, [], fn variable, acc ->
          value =
            :rand.uniform()
            |> Decimal.from_float()
            |> Decimal.mult(multiplier)
            |> Decimal.round(2)

          [{variable, value} | acc]
        end)

      [{:time, t} | row]
    end)
  end

  def generate(time_range, multiplier, interval, variable),
    do: generate(time_range, multiplier, interval, [variable])

  defp(generate_time_points(%{from: from, to: to}, interval)) do
    seconds_in_interval =
      case interval do
        :hour -> 60 * 60
        :day -> 60 * 60 * 24
      end

    number_of_intervals =
      to
      |> DateTime.diff(from, :second)
      |> div(seconds_in_interval)

    # assemble the timestamps in a list
    0..(number_of_intervals - 1)
    |> Enum.map(fn n ->
      DateTime.add(from, n * seconds_in_interval, :second)
    end)
  end
end
