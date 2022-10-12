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

    test "next_n_days/2 should return an inclusive right limit" do
      %{from: from, to: to} = TimeRange.next_n_days(7, @tz)
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
      assert Date.diff(DateTime.to_date(to), DateTime.to_date(from)) == days_in_current_month - 1
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
end
