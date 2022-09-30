defmodule Luminous.TimeRange do
  @type t() :: %__MODULE__{from: DateTime.t(), to: DateTime.t()}

  defstruct [:from, :to]

  @spec new(DateTime.t(), DateTime.t()) :: t()
  def new(from, to), do: %__MODULE__{from: from, to: to}

  @spec from_iso(binary(), binary()) :: t()
  def from_iso(from_iso, to_iso) do
    [from, to] =
      Enum.map([from_iso, to_iso], fn iso ->
        {:ok, dt, _} = DateTime.from_iso8601(iso)
        dt
      end)

    new(from, to)
  end

  @spec from_unix(non_neg_integer(), non_neg_integer()) :: t()
  def from_unix(from_unix, to_unix) do
    [from, to] =
      Enum.map([from_unix, to_unix], fn ut ->
        DateTime.from_unix!(ut)
      end)

    new(from, to)
  end

  @spec to_map(t()) :: map()
  def to_map(time_range), do: Map.from_struct(time_range)

  @spec shift_zone!(t(), binary()) :: t()
  def shift_zone!(time_range, time_zone) do
    new(
      DateTime.shift_zone!(time_range.from, time_zone),
      DateTime.shift_zone!(time_range.to, time_zone)
    )
  end

  @spec today(binary()) :: t()
  def today(tz) do
    from = DateTime.now!(tz) |> round(:day)
    to = add(from, 1, :day)
    new(from, to)
  end

  @spec yesterday(binary()) :: t()
  def yesterday(tz) do
    to = DateTime.now!(tz) |> round(:day)
    from = to |> add(-1, :day)
    new(from, to)
  end

  @spec tomorrow(binary()) :: t()
  def tomorrow(tz) do
    from = DateTime.now!(tz) |> add(1, :day) |> round(:day)
    to = add(from, 1, :day)
    new(from, to)
  end

  @spec last_n_days(non_neg_integer(), binary()) :: t()
  def last_n_days(n, tz) do
    to = DateTime.now!(tz) |> round(:day) |> add(1, :day)
    from = add(to, -n, :day)
    new(from, to)
  end

  @spec next_n_days(non_neg_integer(), binary()) :: t()
  def next_n_days(n, tz) do
    from = DateTime.now!(tz) |> add(1, :day) |> round(:day)
    to = add(from, n, :day)
    new(from, to)
  end

  @spec this_week(binary()) :: t()
  def this_week(tz) do
    from = DateTime.now!(tz) |> round(:week)
    to = add(from, 7, :day)
    new(from, to)
  end

  @spec last_week(binary()) :: t()
  def last_week(tz) do
    to = DateTime.now!(tz) |> round(:week)
    from = add(to, -7, :day)
    new(from, to)
  end

  @spec this_month(binary()) :: t()
  def this_month(tz) do
    from = DateTime.now!(tz) |> round(:month)
    to = add(from, 1, :month)
    new(from, to)
  end

  @spec last_month(binary()) :: t()
  def last_month(tz) do
    to = DateTime.now!(tz) |> round(:month)
    from = add(to, -1, :month)
    new(from, to)
  end

  @spec round(DateTime.t(), atom()) :: DateTime.t()
  def round(dt, :day) do
    start_of_day = Time.new!(0, 0, 0)
    DateTime.new!(DateTime.to_date(dt), start_of_day, dt.time_zone)
  end

  def round(dt, :week) do
    start_of_day = Time.new!(0, 0, 0)
    start_of_week = Date.beginning_of_week(dt)
    DateTime.new!(start_of_week, start_of_day, dt.time_zone)
  end

  def round(dt, :month) do
    start_of_day = Time.new!(0, 0, 0)
    start_of_month = Date.beginning_of_month(dt)
    DateTime.new!(start_of_month, start_of_day, dt.time_zone)
  end

  @spec add(DateTime.t(), integer(), atom()) :: DateTime.t()
  def add(dt, n, :minute) do
    DateTime.add(dt, n * 60, :second)
  end

  def add(dt, n, :hour), do: add(dt, n * 60, :minute)
  def add(dt, n, :day), do: add(dt, 24 * n, :hour)

  def add(%DateTime{:year => year, :month => month} = dt, n, :month) do
    m = month + n

    shifted =
      cond do
        m > 0 ->
          years = div(m - 1, 12)
          month = rem(m - 1, 12) + 1
          %{dt | :year => year + years, :month => month}

        m <= 0 ->
          years = div(m, 12) - 1
          month = 12 + rem(m, 12)
          %{dt | :year => year + years, :month => month}
      end

    # If the shift fails, it's because it's a high day number, and the month
    # shifted to does not have that many days. This will be handled by always
    # shifting to the last day of the month shifted to.
    case :calendar.valid_date({shifted.year, shifted.month, shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)

        cond do
          shifted.day <= last_day ->
            shifted

          :else ->
            %{shifted | :day => last_day}
        end

      true ->
        shifted
    end
  end
end
