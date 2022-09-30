defmodule Luminous.QueryTest do
  use ExUnit.Case

  alias Luminous.Query
  alias Luminous.Query.DataSet

  defmodule TestQueries do
    @behaviour Query
    @impl true
    def query(:normal, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-03T00:00:00Z]}, {:l1, 1}, {:l2, 11}, {"l3", 111}],
        [{:time, ~U[2022-08-04T00:00:00Z]}, {:l1, 2}, {:l2, 12}, {"l3", 112}]
      ]
      |> Query.Result.new()
    end

    def query(:sparse, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-03T00:00:00Z]}, {:l1, 1}, {"l3", 111}],
        [{:time, ~U[2022-08-04T00:00:00Z]}, {:l2, 12}, {"l3", 112}]
      ]
      |> Query.Result.new(
        var_attrs: %{
          "l1" => [type: :bar, order: 0],
          "l2" => [order: 1],
          "l3" => [type: :bar, order: 2]
        }
      )
    end

    def query(:single_stat, _time_range, _variables), do: Query.Result.new(666)

    def query(:multiple_stats, _time_range, _variables) do
      [[{"foo", 11}, {"bar", 13}]]
      |> Query.Result.new(time_series?: false)
    end
  end

  describe "execute and transform" do
    test "fetches and transforms the data from the actual query" do
      results =
        :normal
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      t1 = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)
      t2 = DateTime.to_unix(~U[2022-08-04T00:00:00Z], :millisecond)

      assert [
               %Query.DataSet{
                 rows: [%{x: ^t1, y: 1}, %{x: ^t2, y: 2}],
                 label: "l1",
                 type: :line
               },
               %Query.DataSet{
                 rows: [%{x: ^t1, y: 11}, %{x: ^t2, y: 12}],
                 label: "l2",
                 type: :line
               },
               %Query.DataSet{
                 rows: [%{x: ^t1, y: 111}, %{x: ^t2, y: 112}],
                 label: "l3",
                 type: :line
               }
             ] = results
    end

    test "can fetch and transform sparse data from the query" do
      results =
        :sparse
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      t1 = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)
      t2 = DateTime.to_unix(~U[2022-08-04T00:00:00Z], :millisecond)

      assert [
               %Query.DataSet{
                 rows: [%{x: ^t1, y: 1}],
                 label: "l1",
                 type: :bar
               },
               %Query.DataSet{
                 rows: [%{x: ^t2, y: 12}],
                 label: "l2",
                 type: :line
               },
               %Query.DataSet{
                 rows: [%{x: ^t1, y: 111}, %{x: ^t2, y: 112}],
                 label: "l3",
                 type: :bar
               }
             ] = results
    end

    test "single stat" do
      result =
        :single_stat
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      assert [
               %Query.DataSet{
                 fill: true,
                 label: "",
                 rows: [%{y: 666}],
                 type: :line
               }
             ] = result
    end

    test "multiple stats" do
      results =
        :multiple_stats
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      assert [
               %Query.DataSet{
                 fill: true,
                 label: "foo",
                 rows: [%{y: 11}],
                 type: :line
               },
               %Query.DataSet{
                 fill: true,
                 label: "bar",
                 rows: [%{y: 13}],
                 type: :line
               }
             ] = results
    end
  end

  describe "Dataset statistics" do
    test "calculates the basic statistics" do
      ds = DataSet.new([%{y: 1}, %{y: 3}, %{y: -2}], "foo")

      assert %{label: "foo", n: 3, min: min, max: max, avg: avg, sum: sum} =
               DataSet.statistics(ds)

      assert min == Decimal.new(-2)
      assert max == Decimal.new(3)
      assert avg == Decimal.new(1)
      assert sum == Decimal.new(2)
    end

    test "rounds the average acc. to the max number of decimal digits in the dataset" do
      ds = DataSet.new([%{y: Decimal.new("1.234")}, %{y: Decimal.new("1.11")}], "foo")

      assert %{avg: avg, sum: sum} = DataSet.statistics(ds)
      assert avg == Decimal.new("1.172")
      assert sum == Decimal.new("2.344")
    end

    test "can handle an empty dataset" do
      ds = DataSet.new([], "foo")
      assert %{n: 0, avg: nil, sum: nil, min: nil, max: nil} = DataSet.statistics(ds)
    end

    test "can handle datasets that contain nils" do
      ds = DataSet.new([%{y: 4}, %{y: nil}, %{y: 3}, %{y: 5}, %{y: nil}], "foo")
      assert %{n: 3, avg: avg, sum: sum, min: min, max: max} = DataSet.statistics(ds)
      assert min == Decimal.new(3)
      assert max == Decimal.new(5)
      assert sum == Decimal.new(12)
      assert avg == Decimal.new(4)
    end

    test "can handle datasets with nils only" do
      ds = DataSet.new([%{y: nil}, %{y: nil}], "foo")
      assert %{n: 0, avg: nil, sum: nil, min: nil, max: nil} = DataSet.statistics(ds)
    end
  end
end
