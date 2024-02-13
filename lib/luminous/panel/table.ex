defmodule Luminous.Panel.Table do
  alias Luminous.Attributes

  use Luminous.Panel

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
      hook: [type: :string, default: "TableHook"],
      page_size: [type: :pos_integer, default: 10]
    ]

  @impl true
  def transform(rows, panel) do
    col_defs =
      rows
      |> extract_labels()
      |> Enum.map(fn label ->
        attrs =
          Map.get(panel.data_attributes, label) ||
            Map.get(panel.data_attributes, to_string(label)) ||
            Attributes.parse!(
              [title: to_string(label)],
              data_attributes() ++ Attributes.Schema.data()
            )

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
  def reduce(datasets, panel, _dashboard) do
    columns = Enum.flat_map(datasets, &Map.get(&1, :columns))

    datasets =
      datasets
      |> Enum.map(&Map.get(&1, :rows))
      |> Enum.zip()
      |> Enum.map(&Tuple.to_list/1)
      |> Enum.map(fn
        [m | _] = maps when is_map(m) -> Enum.reduce(maps, %{}, &Map.merge(&2, &1))
        [l | _] = lists when is_list(l) -> lists |> Enum.concat() |> Map.new()
      end)

    %{rows: datasets, columns: columns, attributes: %{page_size: panel.page_size}}
  end

  @impl true
  def actions(), do: [%{label: "Download CSV", event: "download:csv"}]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full z-0">
      <div id={"#{Luminous.Utils.dom_id(@panel)}"} phx-hook={@panel.hook} phx-update="ignore" />
    </div>
    """
  end

  defp extract_labels(rows) when is_list(rows) do
    rows
    |> Enum.flat_map(fn
      m when is_map(m) -> Map.keys(m)
      l when is_list(l) -> Enum.map(l, &elem(&1, 0))
    end)
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
