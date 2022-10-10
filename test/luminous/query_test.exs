defmodule Luminous.QueryTest do
  use ExUnit.Case

  alias Luminous.Query
  alias Luminous.Query.{Attributes, DataSet}

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
        attrs: %{
          "l1" => Attributes.define(type: :bar, order: 0),
          "l2" => Attributes.define(order: 1),
          "l3" => Attributes.define(type: :bar, order: 2)
        }
      )
    end

    def query(:null, _time_range, _variables) do
      Query.Result.new([
        [{:time, ~U[2022-08-03T00:00:00Z]}, {:l1, 1}, {:l2, nil}]
      ])
    end

    def query(:single_stat, _time_range, _variables), do: Query.Result.new(666)

    def query(:multiple_stats, _time_range, _variables) do
      Query.Result.new([{"foo", 11}, {"bar", 13}])
    end
  end

  describe "Query.Result" do
    test "fetches and transforms the data from the actual query" do
      results =
        :normal
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      t1 = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)
      t2 = DateTime.to_unix(~U[2022-08-04T00:00:00Z], :millisecond)

      expected_d1 = [%{x: t1, y: Decimal.new(1)}, %{x: t2, y: Decimal.new(2)}]
      expected_d2 = [%{x: t1, y: Decimal.new(11)}, %{x: t2, y: Decimal.new(12)}]
      expected_d3 = [%{x: t1, y: Decimal.new(111)}, %{x: t2, y: Decimal.new(112)}]

      assert [
               %Query.DataSet{
                 rows: ^expected_d1,
                 label: "l1"
               },
               %Query.DataSet{
                 rows: ^expected_d2,
                 label: "l2"
               },
               %Query.DataSet{
                 rows: ^expected_d3,
                 label: "l3"
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

      expected_d1 = [%{x: t1, y: Decimal.new(1)}]
      expected_d2 = [%{x: t2, y: Decimal.new(12)}]
      expected_d3 = [%{x: t1, y: Decimal.new(111)}, %{x: t2, y: Decimal.new(112)}]

      expected_attrs_1 = Attributes.define(type: :bar, order: 0)
      expected_attrs_2 = Attributes.define(order: 1)
      expected_attrs_3 = Attributes.define(type: :bar, order: 2)

      assert [
               %Query.DataSet{
                 rows: ^expected_d1,
                 label: "l1",
                 attrs: ^expected_attrs_1
               },
               %Query.DataSet{
                 rows: ^expected_d2,
                 label: "l2",
                 attrs: ^expected_attrs_2
               },
               %Query.DataSet{
                 rows: ^expected_d3,
                 label: "l3",
                 attrs: ^expected_attrs_3
               }
             ] = results
    end

    test "can fetch and transform query results that contain nil" do
      results =
        :null
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      t = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)

      expected_d1 = [%{x: t, y: Decimal.new(1)}]
      expected_d2 = []

      assert [
               %Query.DataSet{
                 rows: ^expected_d1,
                 label: "l1"
               },
               %Query.DataSet{
                 rows: ^expected_d2,
                 label: "l2"
               }
             ] = results
    end

    test "single stat" do
      result =
        :single_stat
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      expected = [%{y: Decimal.new(666)}]

      assert [
               %Query.DataSet{
                 label: "",
                 rows: ^expected
               }
             ] = result
    end

    test "multiple stats" do
      results =
        :multiple_stats
        |> Query.define(TestQueries)
        |> Query.execute(nil, [])
        |> Query.Result.transform()

      expected_1 = [%{y: Decimal.new(11)}]
      expected_2 = [%{y: Decimal.new(13)}]

      assert [
               %Query.DataSet{
                 label: "foo",
                 rows: ^expected_1
               },
               %Query.DataSet{
                 label: "bar",
                 rows: ^expected_2
               }
             ] = results
    end
  end

  describe "Dataset.statistics/1" do
    test "calculates the basic statistics" do
      ds = DataSet.new([%{y: Decimal.new(1)}, %{y: Decimal.new(3)}, %{y: Decimal.new(-2)}], "foo")

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
      ds =
        DataSet.new(
          [
            %{y: Decimal.new(4)},
            %{y: nil},
            %{y: Decimal.new(3)},
            %{y: Decimal.new(5)},
            %{y: nil}
          ],
          "foo"
        )

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
