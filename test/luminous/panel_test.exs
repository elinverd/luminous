defmodule Luminous.PanelTest do
  use ExUnit.Case

  alias Luminous.{Attributes, Query, Panel}

  defmodule ChartQueries do
    alias Luminous.Panel

    @behaviour Query
    @impl true
    def query(:normal, _time_range, _variables) do
      [
        %{:time => ~U[2022-08-03T00:00:00Z], :l1 => 1, :l2 => 11, "l3" => 111},
        %{:time => ~U[2022-08-04T00:00:00Z], :l1 => 2, :l2 => 12, "l3" => 112}
      ]
    end

    def query(:sparse, _time_range, _variables) do
      [
        %{:time => ~U[2022-08-03T00:00:00Z], :l1 => 1, "l3" => 111},
        %{:time => ~U[2022-08-04T00:00:00Z], :l2 => 12, "l3" => 112}
      ]
    end

    def query(:null, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-03T00:00:00Z]}, {:l1, 1}, {:l2, nil}]
      ]
    end
  end

  describe "Chart Panel" do
    test "fetches and transforms the data from the actual query" do
      panel =
        Panel.define!(type: Panel.Chart, id: :foo, queries: [Query.define(:normal, ChartQueries)])

      results =
        panel
        |> Panel.refresh([], nil)
        |> Panel.Chart.reduce(panel, %{time_zone: "Etc/UTC"})

      t1 = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)
      t2 = DateTime.to_unix(~U[2022-08-04T00:00:00Z], :millisecond)

      default_attrs =
        Attributes.parse!([], Panel.Chart.data_attributes() ++ Attributes.Schema.data())

      expected_datasets = [
        %{
          rows: [%{x: t1, y: Decimal.new(1)}, %{x: t2, y: Decimal.new(2)}],
          label: "l1",
          attrs: default_attrs,
          stats: %{
            avg: Decimal.new(2),
            label: "l1",
            max: Decimal.new(2),
            min: Decimal.new(1),
            n: 2,
            sum: Decimal.new(3)
          }
        },
        %{
          rows: [%{x: t1, y: Decimal.new(11)}, %{x: t2, y: Decimal.new(12)}],
          label: "l2",
          attrs: default_attrs,
          stats: %{
            avg: Decimal.new(12),
            label: "l2",
            max: Decimal.new(12),
            min: Decimal.new(11),
            n: 2,
            sum: Decimal.new(23)
          }
        },
        %{
          rows: [%{x: t1, y: Decimal.new(111)}, %{x: t2, y: Decimal.new(112)}],
          label: "l3",
          attrs: default_attrs,
          stats: %{
            avg: Decimal.new(112),
            label: "l3",
            max: Decimal.new(112),
            min: Decimal.new(111),
            n: 2,
            sum: Decimal.new(223)
          }
        }
      ]

      expected_results = %{
        datasets: expected_datasets,
        ylabel: panel.ylabel,
        xlabel: panel.xlabel,
        stacked_x: panel.stacked_x,
        stacked_y: panel.stacked_y,
        y_min_value: panel.y_min_value,
        y_max_value: panel.y_max_value,
        time_zone: "Etc/UTC"
      }

      assert ^expected_results = results
    end

    test "can fetch and transform sparse data from the query" do
      panel =
        Panel.define!(
          type: Panel.Chart,
          id: :foo,
          queries: [Query.define(:sparse, ChartQueries)],
          data_attributes: %{
            "l1" => [type: :bar, order: 0],
            "l2" => [order: 1],
            "l3" => [type: :bar, order: 2]
          }
        )

      results =
        panel
        |> Panel.refresh([], nil)
        |> Panel.Chart.reduce(panel, %{time_zone: "Etc/UTC"})

      t1 = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)
      t2 = DateTime.to_unix(~U[2022-08-04T00:00:00Z], :millisecond)

      default_schema = Attributes.Schema.data() ++ Panel.Chart.data_attributes()

      expected_results = %{
        datasets: [
          %{
            rows: [%{x: t1, y: Decimal.new(1)}],
            label: "l1",
            attrs: Attributes.parse!([type: :bar, order: 0], default_schema),
            stats: %{
              avg: Decimal.new(1),
              label: "l1",
              max: Decimal.new(1),
              min: Decimal.new(1),
              n: 1,
              sum: Decimal.new(1)
            }
          },
          %{
            rows: [%{x: t2, y: Decimal.new(12)}],
            label: "l2",
            attrs: Attributes.parse!([order: 1], default_schema),
            stats: %{
              avg: Decimal.new(12),
              label: "l2",
              max: Decimal.new(12),
              min: Decimal.new(12),
              n: 1,
              sum: Decimal.new(12)
            }
          },
          %{
            rows: [%{x: t1, y: Decimal.new(111)}, %{x: t2, y: Decimal.new(112)}],
            label: "l3",
            attrs: Attributes.parse!([type: :bar, order: 2], default_schema),
            stats: %{
              avg: Decimal.new(112),
              label: "l3",
              max: Decimal.new(112),
              min: Decimal.new(111),
              n: 2,
              sum: Decimal.new(223)
            }
          }
        ],
        ylabel: panel.ylabel,
        xlabel: panel.xlabel,
        stacked_x: panel.stacked_x,
        stacked_y: panel.stacked_y,
        y_min_value: panel.y_min_value,
        y_max_value: panel.y_max_value,
        time_zone: "Etc/UTC"
      }

      assert ^expected_results = results
    end

    test "can fetch and transform query results that contain nil" do
      panel =
        Panel.define!(
          type: Panel.Chart,
          id: :foo,
          queries: [Query.define(:null, ChartQueries)]
        )

      results =
        panel
        |> Panel.refresh([], nil)
        |> Panel.Chart.reduce(panel, %{time_zone: "Etc/UTC"})

      default_attrs =
        Attributes.parse!([], Panel.Chart.data_attributes() ++ Attributes.Schema.data())

      t = DateTime.to_unix(~U[2022-08-03T00:00:00Z], :millisecond)

      expected_results = %{
        datasets: [
          %{
            rows: [%{x: t, y: Decimal.new(1)}],
            label: "l1",
            attrs: default_attrs,
            stats: %{
              avg: Decimal.new(1),
              label: "l1",
              max: Decimal.new(1),
              min: Decimal.new(1),
              n: 1,
              sum: Decimal.new(1)
            }
          },
          %{
            rows: [],
            label: "l2",
            attrs: default_attrs,
            stats: %{avg: nil, label: "l2", max: nil, min: nil, n: 0, sum: nil}
          }
        ],
        ylabel: panel.ylabel,
        xlabel: panel.xlabel,
        stacked_x: panel.stacked_x,
        stacked_y: panel.stacked_y,
        y_min_value: panel.y_min_value,
        y_max_value: panel.y_max_value,
        time_zone: "Etc/UTC"
      }

      assert ^expected_results = results
    end
  end

  describe "Chart Statistics" do
    test "calculates the basic statistics" do
      ds = [%{y: Decimal.new(1)}, %{y: Decimal.new(3)}, %{y: Decimal.new(-2)}]

      assert %{label: "foo", n: 3, min: min, max: max, avg: avg, sum: sum} =
               Panel.Chart.statistics(ds, "foo")

      assert min == Decimal.new(-2)
      assert max == Decimal.new(3)
      assert avg == Decimal.new(1)
      assert sum == Decimal.new(2)
    end

    test "rounds the average acc. to the max number of decimal digits in the dataset" do
      ds = [%{y: Decimal.new("1.234")}, %{y: Decimal.new("1.11")}]

      assert %{avg: avg, sum: sum} = Panel.Chart.statistics(ds, "foo")
      assert avg == Decimal.new("1.172")
      assert sum == Decimal.new("2.344")
    end

    test "can handle an empty dataset" do
      assert %{n: 0, avg: nil, sum: nil, min: nil, max: nil} = Panel.Chart.statistics([], "foo")
    end

    test "can handle datasets that contain nils" do
      ds = [
        %{y: Decimal.new(4)},
        %{y: nil},
        %{y: Decimal.new(3)},
        %{y: Decimal.new(5)},
        %{y: nil}
      ]

      assert %{n: 3, avg: avg, sum: sum, min: min, max: max} = Panel.Chart.statistics(ds, "foo")
      assert min == Decimal.new(3)
      assert max == Decimal.new(5)
      assert sum == Decimal.new(12)
      assert avg == Decimal.new(4)
    end

    test "can handle datasets with nils only" do
      ds = [%{y: nil}, %{y: nil}]
      assert %{n: 0, avg: nil, sum: nil, min: nil, max: nil} = Panel.Chart.statistics(ds, "foo")
    end
  end

  defmodule StatQueries do
    @behaviour Query
    @impl true
    def query(:single_stat, _time_range, _variables), do: %{"foo" => 666}

    def query(:multiple_stats, _time_range, _variables) do
      %{"foo" => 11, "bar" => 13}
    end
  end

  describe "Stat Panel" do
    test "single stat" do
      panel =
        Panel.define!(
          type: Panel.Stat,
          id: :foo,
          queries: [Query.define(:single_stat, StatQueries)]
        )

      results =
        panel
        |> Panel.refresh([], nil)
        |> Panel.Stat.reduce(panel, "")

      assert %{stats: [%{title: nil, unit: nil, value: 666}]} = results
    end

    test "multiple stats" do
      panel =
        Panel.define!(
          type: Panel.Stat,
          id: :foo,
          queries: [Query.define(:multiple_stats, StatQueries)],
          data_attributes: %{
            "bar" => [order: 0],
            "foo" => [title: "Foo", unit: "mckk", order: 1]
          }
        )

      results =
        panel
        |> Panel.refresh([], nil)
        |> Panel.Stat.reduce(panel, "")

      assert %{
               stats: [
                 %{
                   title: "",
                   unit: "",
                   value: 13
                 },
                 %{
                   title: "Foo",
                   unit: "mckk",
                   value: 11
                 }
               ]
             } = results
    end
  end

  defmodule TableQueries do
    @behaviour Query
    @impl true
    def query(:table_1, _time_range, _variables) do
      [%{"foo" => 666, "bar" => "hello"}, %{"foo" => 667, "bar" => "goodbye"}]
    end

    def query(:table_2, _time_range, _variables) do
      [%{"baz" => 1}, %{"baz" => 2}]
    end
  end

  describe "Table panel" do
    test "table should show all query columns even those with no data_attributes" do
      panel =
        Panel.define!(
          type: Panel.Table,
          id: :ttt,
          queries: [Query.define(:table_1, TableQueries)],
          # no data attribute for "bar"
          data_attributes: %{"foo" => [halign: :right]}
        )

      assert %{rows: [row | _], columns: columns} =
               panel
               |> Panel.refresh([], nil)
               |> Panel.Table.reduce(panel, nil)

      # both labels are included in the results
      col = Enum.find(columns, &(&1.field == "foo"))
      refute is_nil(col)
      assert :right = col.hozAlign

      assert row["foo"] == 666

      col = Enum.find(columns, &(&1.field == "bar"))
      refute is_nil(col)
      assert :left = col.hozAlign

      assert row["bar"] == "hello"
    end

    test "table should include the results from multiple queries" do
      panel =
        Panel.define!(
          type: Panel.Table,
          id: :ttt,
          queries: [
            Query.define(:table_1, TableQueries),
            Query.define(:table_2, TableQueries)
          ],
          # no data attribute for "bar"
          data_attributes: %{"foo" => [halign: :right]}
        )

      assert %{rows: [row | _], columns: columns} =
               panel
               |> Panel.refresh([], nil)
               |> Panel.Table.reduce(panel, nil)

      assert Enum.find(columns, &(&1.field == "foo"))
      assert row["foo"] == 666

      assert Enum.find(columns, &(&1.field == "baz"))
      assert row["baz"] == 1
    end
  end
end
