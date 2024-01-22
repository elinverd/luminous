defmodule Luminous.Panel.Table do
  @behaviour Luminous.Panel

  @impl true
  def data_attributes(),
    do: [
      title: [type: :string, default: ""],
      halign: [type: {:in, [:left, :right, :center]}, default: :left],
      table_totals: [type: {:in, [:avg, :sum, nil]}, default: nil],
      number_formatting: [
        type: :keyword_list,
        keys: [
          thousand_separator: [type: {:or, [:string, :boolean]}, default: false],
          decimal_separator: [type: {:or, [:string, :boolean]}, default: false],
          precision: [type: {:or, [:non_neg_integer, :boolean]}, default: false]
        ]
      ]
    ]

  @impl true
  def panel_attributes(),
    do: [
      hook: [type: :string, default: "TableHook"]
    ]

  @impl true
  def transform(data, panel) do
    col_defs =
      panel.data_attributes
      |> Enum.sort_by(fn {_, attr} -> attr.order end)
      |> Enum.map(fn {label, attr} ->
        %{
          field: label,
          title: attr.title || label,
          hozAlign: attr.halign,
          headerHozAlign: attr.halign
        }
        |> add_table_totals_option(attr)
        |> add_number_formatting_option(attr)
      end)

    rows =
      Enum.map(data, fn row ->
        Enum.reduce(row, %{}, fn {label, value}, acc -> Map.put(acc, label, value) end)
      end)

    [%{rows: rows, columns: col_defs}]
  end

  defp add_table_totals_option(col_params, attr) do
    if is_nil(attr.table_totals),
      do: col_params,
      else: Map.put(col_params, :bottomCalc, attr.table_totals)
  end

  defp add_number_formatting_option(col_params, %{number_formatting: nf}) do
    formatterParams = %{
      thousand: Keyword.get(nf, :thousand_separator),
      decimal: Keyword.get(nf, :decimal_separator),
      precision: Keyword.get(nf, :precision)
    }

    col_params
    |> Map.put(:formatter, "money")
    |> Map.put(:formatterParams, formatterParams)
    |> Map.put(:bottomCalcFormatter, "money")
    |> Map.put(:bottomCalcFormatterParams, formatterParams)
  end

  defp add_number_formatting_option(col_params, _), do: col_params
end
