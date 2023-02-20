defmodule Luminous.Panel.Stat do
  alias Luminous.Query
  @behaviour Luminous.Panel
  @impl true
  def transform(%Query.Result{rows: rows, attrs: attrs}) when not is_nil(rows) do
    rows
    |> Enum.sort_by(fn {label, _} ->
      if(attr = attrs[label], do: attr.order)
    end)
    |> Enum.map(fn {label, value} ->
      %{
        title: if(attr = attrs[label], do: attr.title),
        value: value,
        unit: if(attr = attrs[label], do: attr.unit)
      }
    end)
  end

  def transform(_), do: []
end
