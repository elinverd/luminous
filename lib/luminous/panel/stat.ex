defmodule Luminous.Panel.Stat do
  alias Luminous.Query
  require Decimal

  @behaviour Luminous.Panel
  @impl true
  # do we have a single number?
  def transform(%Query.Result{rows: n}) when is_number(n) or Decimal.is_decimal(n) do
    [%{title: nil, value: n, unit: nil}]
  end

  # we have a map of values and the relevant attributes potentially
  def transform(%Query.Result{rows: rows, attrs: attrs}) when is_map(rows) do
    rows
    |> Enum.sort_by(fn {label, _} -> if(attr = attrs[label], do: attr.order) end)
    |> Enum.map(fn {label, value} ->
      %{
        title: if(attr = attrs[label], do: attr.title),
        value: value,
        unit: if(attr = attrs[label], do: attr.unit)
      }
    end)
  end

  # fallback
  def transform(_), do: []
end
