defmodule Luminous.Panel.Stat do
  require Decimal

  @behaviour Luminous.Panel

  @impl true
  def data_attributes(), do: []

  @impl true
  def panel_attributes(), do: []

  @impl true
  # do we have a single number?
  def transform(n, _panel) when is_number(n) or Decimal.is_decimal(n) do
    [%{title: nil, value: n, unit: nil}]
  end

  # we have a map of values and the relevant attributes potentially
  def transform(data, panel) when is_map(data) or is_list(data) do
    data
    |> Enum.sort_by(fn {label, _} -> if(attr = panel.data_attributes[label], do: attr.order) end)
    |> Enum.map(fn {label, value} ->
      %{
        title: if(attr = panel.data_attributes[label], do: attr.title),
        value: value,
        unit: if(attr = panel.data_attributes[label], do: attr.unit)
      }
    end)
  end

  # fallback
  def transform(_), do: []
end
