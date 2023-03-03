defmodule Luminous.TimeRangeTest do
  use ExUnit.Case, async: true

  alias Luminous.TimeRange

  @tz "Europe/Athens"

  describe "Preset functions" do
    test "today/1 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.today(@tz)
      assert DateTime.to_date(from) == DateTime.to_date(to)
    end

    test "yesterday/1 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.yesterday(@tz)
      assert DateTime.to_date(from) == DateTime.to_date(to)
    end

    test "tomorrow/1 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.tomorrow(@tz)
      assert DateTime.to_date(from) == DateTime.to_date(to)
    end

    test "last_n_days/2 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.last_n_days(7, @tz)
      assert Date.diff(DateTime.to_date(to), DateTime.to_date(from)) == 6
    end

    test "this_week/1 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.this_week(@tz)
      assert Date.diff(DateTime.to_date(to), DateTime.to_date(from)) == 6
    end

    test "last_week/1 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.last_week(@tz)
      assert Date.diff(DateTime.to_date(to), DateTime.to_date(from)) == 6
    end

    test "this_month/1 should return an inclusive right limit" do
      days_in_current_month =
        @tz
        |> DateTime.now!()
        |> DateTime.to_date()
        |> Date.days_in_month()

      %{from: from, to: to} = TimeRange.this_month(@tz)
      days = Date.diff(DateTime.to_date(to), DateTime.to_date(from))
      assert days == days_in_current_month - 1
    end

    test "last_month/1 should return an inclusive right limit" do
      days_in_previous_month =
        @tz
        |> DateTime.now!()
        |> DateTime.to_date()
        |> Date.beginning_of_month()
        |> Date.add(-1)
        |> Date.days_in_month()

      %{from: from, to: to} = TimeRange.last_month(@tz)
      assert Date.diff(DateTime.to_date(to), DateTime.to_date(from)) == days_in_previous_month - 1
    end
  end

  describe "DST changes [winter -> summer]" do
    test "today" do
      now = DateTime.new!(~D[2023-03-26], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-26], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-26], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.today(@tz, now)
    end

    test "yesterday" do
      now = DateTime.new!(~D[2023-03-27], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-26], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-26], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.yesterday(@tz, now)
    end

    test "tomorrow" do
      now = DateTime.new!(~D[2023-03-25], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-26], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-26], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.tomorrow(@tz, now)
    end

    test "last_n_days" do
      now = DateTime.new!(~D[2023-03-27], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-26], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-27], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.last_n_days(2, @tz, now)
    end

    test "this_week" do
      now = DateTime.new!(~D[2023-03-23], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-20], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-26], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.this_week(@tz, now)
    end

    test "last_week" do
      now = DateTime.new!(~D[2023-03-28], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-20], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-26], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.last_week(@tz, now)
    end

    test "this_month" do
      now = DateTime.new!(~D[2023-03-28], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-01], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-31], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.this_month(@tz, now)
    end

    test "last_month" do
      now = DateTime.new!(~D[2023-04-11], ~T[01:00:00], @tz)

      expected = %TimeRange{
        from: DateTime.new!(~D[2023-03-01], ~T[00:00:00], @tz),
        to: DateTime.new!(~D[2023-03-31], ~T[23:59:59], @tz)
      }

      assert ^expected = TimeRange.last_month(@tz, now)
    end
  end
end
