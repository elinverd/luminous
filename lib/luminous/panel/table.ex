defmodule Luminous.Panel.Table do
  alias Luminous.Query
  @behaviour Luminous.Panel
  @impl true

  def transform(%Query.Result{rows: rows, attrs: attrs}) do
    col_defs =
      attrs
      |> Enum.sort_by(fn {_, attr} -> attr.order end)
      |> Enum.map(fn {label, attr} ->
        col_params = %{
          field: label,
          title: attr.title || label,
          hozAlign: attr.halign,
          headerHozAlign: attr.halign
        }

        case attr.table_totals do
          nil ->
            col_params

          {totals_function, precision} ->
            col_params
            |> Map.put(:bottomCalc, totals_function)
            |> Map.put(:bottomCalcParams, %{precision: precision})

          totals_function ->
            Map.put(col_params, :bottomCalc, totals_function)
        end
      end)

    rows =
      Enum.map(rows, fn row ->
        Enum.reduce(row, %{}, fn {label, value}, acc -> Map.put(acc, label, value) end)
      end)

    [%{rows: rows, columns: col_defs}]
  end
end
