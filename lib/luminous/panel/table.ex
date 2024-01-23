defmodule Luminous.Panel.Table do
  alias Luminous.Attributes

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
  def transform(rows, panel) do
    col_defs =
      rows
      |> extract_labels()
      |> Enum.map(fn label ->
        attrs =
          Map.get(panel.data_attributes, label) ||
            Attributes.parse!([], data_attributes() ++ Attributes.Data.common())

        {label, attrs}
      end)
      |> Enum.sort_by(fn {_, attrs} -> attrs.order end)
      |> Enum.map(fn {label, attrs} ->
        %{
          field: label,
          title: attrs.title,
          hozAlign: attrs.halign,
          headerHozAlign: attrs.halign
        }
        |> add_table_totals_option(attrs)
        |> add_number_formatting_option(attrs)
      end)

    %{rows: rows, columns: col_defs}
  end

  @impl true
  def reduce(datasets, _panel, _dashboard) do
    columns = Enum.flat_map(datasets, &Map.get(&1, :columns))

    datasets =
      datasets
      |> Enum.map(&Map.get(&1, :rows))
      |> Enum.zip()
      |> Enum.map(&Tuple.to_list/1)
      |> Enum.map(fn maps ->
        Enum.reduce(maps, %{}, &Map.merge(&2, &1))
      end)

    %{rows: datasets, columns: columns}
  end

  defp extract_labels(rows) when is_list(rows) do
    rows
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
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
