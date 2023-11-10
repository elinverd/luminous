defmodule Luminous.Panel.Table do
  @behaviour Luminous.Panel

  alias Luminous.Query
  alias Luminous.Query.Attributes.NumberFormattingOptions

  @impl true
  def transform(%Query.Result{rows: rows, attrs: attrs}) do
    col_defs =
      attrs
      |> Enum.sort_by(fn {_, attr} -> attr.order end)
      |> Enum.map(fn {label, attr} ->
        %{
          field: label,
          title: attr.title || label,
          hozAlign: attr.halign,
          headerHozAlign: attr.halign
        }
        |> parse_table_totals_option(attr)
        |> parse_number_formatting_option(attr)
      end)

    rows =
      Enum.map(rows, fn row ->
        Enum.reduce(row, %{}, fn {label, value}, acc -> Map.put(acc, label, value) end)
      end)

    [%{rows: rows, columns: col_defs}]
  end

  defp parse_table_totals_option(col_params, attr) do
    case attr.table_totals do
      nil ->
        col_params

      totals_function ->
        Map.put(col_params, :bottomCalc, totals_function)
    end
  end

  defp parse_number_formatting_option(col_params, attr) do
    case attr.number_formatting do
      %NumberFormattingOptions{} = options ->
        formatterParams = %{
          decimal: options.decimal_separator || false,
          thousand: options.thousand_separator || false,
          precision: options.precision || false
        }

        col_params
        |> Map.put(:formatter, "money")
        |> Map.put(:formatterParams, formatterParams)
        |> Map.put(:bottomCalcFormatter, "money")
        |> Map.put(:bottomCalcFormatterParams, formatterParams)

      _ ->
        col_params
    end
  end
end
