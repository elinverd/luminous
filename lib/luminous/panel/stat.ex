defmodule Luminous.Panel.Stat do
  require Decimal

  alias Luminous.Utils

  use Luminous.Panel

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

  @impl true
  def reduce(datasets, _panel, _dashboard), do: %{stats: datasets}

  @impl true
  def render(assigns) do
    ~H"""
      <%= if is_nil(@data) || length(@data.stats) == 0 do %>
        <div class="flex flex-row items-center justify-center">
          <div id={"#{Utils.dom_id(@panel)}-stat-values"} class="text-4xl font-bold">-</div>
        </div>
      <% else %>
        <div id={"#{Utils.dom_id(@panel)}-stat-values"} class={stats_grid_structure(length(@data.stats))}>
          <%= for column <- @data.stats do %>
          <div class="flex flex-col items-center">
            <div class="text-lg"><span><%= column.title %></span></div>
            <div><span class="text-4xl font-bold"><%= Utils.print_number(column.value) %></span> <span class="text-2xl font-semibold"><%= column.unit %></span></div>

          </div>
          <% end %>
        </div>
      <% end %>
    """
  end

  defp stats_grid_structure(1), do: "grid grid-cols-1 w-full"
  defp stats_grid_structure(2), do: "grid grid-cols-2 w-full"
  defp stats_grid_structure(3), do: "grid grid-cols-3 w-full"
  defp stats_grid_structure(_), do: "grid grid-cols-4 w-full"
end
