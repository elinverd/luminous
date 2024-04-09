defmodule Luminous.Panel.Stat do
  require Decimal

  alias Luminous.{Dashboard, Utils}

  use Luminous.Panel

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
    <%= case Dashboard.get_data(@dashboard, @panel.id) do %>
      <% %{stats: [_ | _] = stats} -> %>
        <div id={"#{Utils.dom_id(@panel)}-stat-values"} class={stats_grid_structure(length(stats))}>
          <%= for {column, index} <- Enum.with_index(stats) do %>
            <%= if Utils.dom_id(@panel) == "panel-p11" do %>
              <% IO.inspect(stats) %>
            <% end %>
            <div class="flex flex-col items-center">
              <div class="grow">
                <p id={"#{Utils.dom_id(@panel)}-stat-#{index}-column-title"} class="text-lg">
                  <%= column.title %>
                </p>
              </div>
              <div>
                <span id={"#{Utils.dom_id(@panel)}-stat-#{index}-value"} class="text-4xl font-bold">
                  <%= Utils.print_number(column.value) %>
                </span>
                <span id={"#{Utils.dom_id(@panel)}-stat-#{index}-unit"} class="text-2xl font-semibold">
                  <%= column.unit %>
                </span>
              </div>
            </div>
          <% end %>
        </div>
      <% _ -> %>
        <div class="flex flex-row items-center justify-center">
          <div id={"#{Utils.dom_id(@panel)}-stat-values"} class="text-4xl font-bold">-</div>
        </div>
    <% end %>
    """
  end

  defp stats_grid_structure(1), do: "grid grid-cols-1 w-full"
  defp stats_grid_structure(2), do: "grid grid-cols-2 w-full"
  defp stats_grid_structure(3), do: "grid grid-cols-3 w-full"
  defp stats_grid_structure(_), do: "grid grid-cols-2 gap-2 w-full"
end
