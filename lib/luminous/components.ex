defmodule Luminous.Components do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias Luminous.{Query, Helpers}

  @doc """
  the dashboard component is responsible for rendering all the necessary elements:
  - title
  - variables
  - time range selector
  - panels

  it also registers callbacks for reacting to panel loading states
  """
  def dashboard(
        %{dashboard: dashboard, stats: stats, panel_statistics: panel_statistics} = assigns
      ) do
    ~H"""
    <.listeners />
    <div class="relative mx-8 lg:mx-auto max-w-screen-lg">
      <div class="py-4 z-10 flex flex-col space-y-4 sticky top-0 backdrop-blur-sm backdrop-grayscale opacity-100 ">

        <div class="pb-4 text-4xl font-bold text-center "><%= dashboard.title %></div>
        <div class="flex flex-col md:flex-row justify-between">
          <div class="flex space-x-2 items-center">
            <%= for var <- dashboard.variables do %>
              <.variable variable={var} />
            <% end %>
          </div>

          <div class="flex space-x-2 items-center">
            <.time_range dashboard={dashboard} />
          </div>
        </div>
      </div>

      <div class="z-0 flex flex-col w-full space-y-8">
        <%= for panel <- dashboard.panels do %>
          <.panel panel={panel} stats={stats} variables={dashboard.variables} panel_statistics={panel_statistics} time_range_selector={dashboard.time_range_selector} />
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  this component registers the js event listeners
  for the panel spinners
  """
  def listeners(assigns) do
    ~H"""
    <script>
      window.addEventListener(`phx:panel:load:start`, (e) => {
        let el = document.getElementById(e.detail.id+"-loading")
        if(el) {
          el.classList.remove("hidden")
        }
      })
      window.addEventListener(`phx:panel:load:end`, (e) => {
        let el = document.getElementById(e.detail.id+"-loading")
        if(el) {
          el.classList.add("hidden")
        }
      })
    </script>
    """
  end

  @doc """
  this component is responsible for rendering the panel's data
  depending on the panel's type, there will be a different visualization
  """
  def panel(
        %{
          panel: %{type: :chart} = panel,
          variables: variables,
          panel_statistics: panel_statistics
        } = assigns
      ) do
    time_range_selector_id =
      assigns
      |> Map.get(:time_range_selector, %{})
      |> Map.get(:id)

    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 shadow-lg px-4 py-6">
      <div class="flex relative w-full justify-center">
        <div id={"#{panel.id}-loading"} class="absolute inline-block top-0 left-0 hidden" role="status" phx-update="ignore">
          <svg aria-hidden="true" class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
            <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <div id={"#{panel_id(panel)}-actions"} class="absolute inline-block top-0 right-0" x-data="{open: false}" @click.away="open = false">
          <div tabindex="0" class="w-6 h-6 focus:outline-none" @click="open = true">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
              <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/>
            </svg>
          </div>
          <ul x-show="open" x-transition:enter="transition ease-out duration-100" x-transition:enter-start="opacity-0 scale-90" x-transition:enter-end="opacity-100 scale-100"
            class="absolute p-2 min-w-max z-50 bg-white rounded-lg shadow-lg text-sm right-0">
            <li @click="open = false" class="text-left rounded-lg cursor-pointer hover:bg-slate-200">
              <a href="#" class="block px-4 py-3" phx-click={JS.dispatch("panel:#{panel_id(panel)}:download:csv", to: "##{panel_id(panel)}")}>
                Download CSV
              </a>
            </li>
            <li @click="open = false" class="text-left rounded-lg cursor-pointer hover:bg-slate-200">
              <a href="#" class="block px-4 py-3" phx-click={JS.dispatch("panel:#{panel_id(panel)}:download:png", to: "##{panel_id(panel)}")}>
                Download image
              </a>
            </li>
          </ul>
        </div>

        <div class="flex flex-row space-x-4">
          <div id={"#{panel_id(panel)}-title"} class="text-xl font-medium"><%= Helpers.interpolate(panel.title, variables) %></div>
          <.description description={panel.description}/>
        </div>
      </div>

      <div class="w-full ">
        <div id={"#{panel_id(panel)}-container"} phx-update="ignore">
          <canvas id={panel_id(panel)} time-range-selector-id={time_range_selector_id} phx-hook={panel.hook}></canvas>
        </div>
        <.panel_statistics panel_statistics={panel_statistics[panel.id]}/>
      </div>
    </div>
    """
  end

  def panel(%{panel: %{type: :stat} = panel, stats: stats, variables: variables} = assigns) do
    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 shadow-lg px-4 py-6">
      <div class="flex relative w-full justify-center">
        <div id={"#{panel.id}-loading"} class="absolute inline-block top-0 left-0 hidden" role="status" phx-update="ignore">
          <svg aria-hidden="true" class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
            <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <%= if panel.title != "" or panel.description != "" do %>
          <div class="flex flex-row space-x-4">
            <div id={"#{panel_id(panel)}-title"} class="text-xl font-medium"><%= Helpers.interpolate(panel.title, variables) %></div>
            <.description description={panel.description}/>
          </div>
        <% end %>
      </div>

        <%= if datasets = stats[panel.id] do %>
          <div id={"#{panel_id(panel)}-stat-values"} class={stats_grid_structure(length(datasets))}>
            <%= for dataset <- datasets do %>
              <div class="flex flex-col items-center">
                <%= if dataset.label do %>
                  <div class="text-lg"><%= dataset.label %></div>
                <% end %>

                <%= if value = Query.DataSet.first_value(dataset) do %>
                  <div><span class="text-4xl font-bold"><%= print_number(value) %></span> <span class="text-2xl font-semibold"><%= dataset.attrs.unit %></span></div>
                <% else %>
                  <span class="text-4xl font-bold">-</span>
                <% end %>

              </div>
            <% end %>
          </div>
        <% else %>
          <div class="flex flex-row items-center justify-center">
            <div class="text-4xl font-bold">-</div>
          </div>
        <% end %>
    </div>
    """
  end

  def panel_statistics(%{panel_statistics: nil} = assigns), do: ~H""

  def panel_statistics(%{panel_statistics: statistics} = assigns) when length(statistics) == 0,
    do: ~H""

  def panel_statistics(%{panel_statistics: statistics} = assigns) do
    ~H"""
    <div class="grid grid-cols-10 gap-x-4 mt-2 mx-8 text-right text-xs">
      <div class="col-span-5 text-xs font-semibold"></div>
      <div class="font-semibold">N</div>
      <div class="font-semibold">Min</div>
      <div class="font-semibold">Max</div>
      <div class="font-semibold">Avg</div>
      <div class="font-semibold">Total</div>

      <%= for var <- statistics do %>
        <div class="col-span-5 truncate"><%= var.label %></div>
        <div><%= var.n %></div>
        <div><%= print_number(var.min) %></div>
        <div><%= print_number(var.max) %></div>
        <div><%= print_number(var.avg) %></div>
        <div><%= print_number(var.sum) %></div>
      <% end %>
    </div>
    """
  end

  def time_range(%{dashboard: dashboard} = assigns) do
    ~H"""
      <div class="flex items-center no-animation cursor-default space-x-4">
        <div class="flex items-center rounded-lg border border-slate-800 h-8 cursor-pointer">
          <!-- Date picker -->
          <input id={dashboard.time_range_selector.id} phx-hook={dashboard.time_range_selector.hook} phx-update="ignore" readonly="readonly"
            class="h-8 w-52 rounded-lg rounded-r-none cursor-pointer bg-transparent text-sm text-center uppercase font-bold hover:text-white hover:bg-slate-800 focus:outline-none active:bg-slate-900" />
          <!-- Presets button & dropdown -->
          <div class="relative" x-data="{open: false}" @click.away="open = false">
            <button class="h-8 px-1 rounded-lg rounded-l-none bg-transparent hover:bg-slate-800 hover:text-white focus:outline-none active:bg-slate-900" @click="open = true">
              <svg id="chevron-down" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
            <ul id="preset-dropdown" x-show="open" x-transition:enter="transition ease-out duration-100" x-transition:enter-start="opacity-0 scale-90" x-transition:enter-end="opacity-100 scale-100"
              class="absolute p-2 min-w-max z-50 bg-white rounded-lg shadow-lg top-10 right-0">
              <%= for preset <- Luminous.TimeRangeSelector.presets() do %>
                <li @click="open = false" class="text-left rounded-lg cursor-pointer hover:bg-slate-200">
                  <a href="#" class="block px-4 py-3" id={"time-range-preset-#{preset}"} phx-click="preset_time_range_selected" phx-value-preset={preset} @click="open = false">
                    <%= preset %>
                  </a>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
        <div class="px-2 rounded-full bg-slate-800 text-sm font-bold text-white cursor-default">
          <%= dashboard.time_zone |> DateTime.now!() |> Calendar.strftime("%Z") %>
        </div>
      </div>
    """
  end

  def variable(%{variable: variable} = assigns) do
    ~H"""
    <div id={"#{variable.id}-dropdown"} class="relative" x-data="{open: false}" @click.away="open = false">
      <button @click="open = true" class="h-8 px-3 py-2.5 flex items-center gap-2 text-sm text-center font-bold uppercase rounded-lg border border-slate-800 hover:text-white hover:bg-slate-800 focus:outline-none transition duration active:bg-slate-900 active:scale-95">
        <div class="text-left text-ellipsis whitespace-nowrap overflow-hidden max-w-xs">
          <span class="text-xs"><%= "#{variable.label}: " %></span><%= variable.current.label %>
        </div>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </button>
      <!-- Dropdown content -->
      <ul id={"#{variable.id}-dropdown-content"} x-show="open" x-transition:enter="transition ease-out duration-100" x-transition:enter-start="opacity-0 scale-90" x-transition:enter-end="opacity-100 scale-100"
        class="absolute p-2 min-w-max max-h-96 overflow-auto z-50 bg-white rounded-lg shadow-lg">
        <%= for %{label: label, value: value} <- variable.values do %>
          <li @click="open = false" class="text-left rounded-lg cursor-pointer hover:bg-slate-200">
            <a href="#" id={"#{variable.id}-#{value}"} class="block px-4 py-3" phx-click="variable_updated" phx-value-variable={"#{variable.id}"} phx-value-value={"#{value}"}>
              <%= label %>
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def description(%{description: nil} = assigns), do: ~H""

  def description(%{description: description} = assigns) do
    ~H"""
      <div data-tip={description} class="tooltip z-50">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    </div>
    """
  end

  def panel_id(panel), do: "panel-#{panel.id}"

  defp print_number(n) do
    case n do
      %Decimal{} = n ->
        Decimal.to_string(n)

      _ ->
        n
    end
  end

  defp stats_grid_structure(1), do: "grid grid-cols-1 w-full"
  defp stats_grid_structure(2), do: "grid grid-cols-2 w-full"
  defp stats_grid_structure(3), do: "grid grid-cols-3 w-full"
  defp stats_grid_structure(_), do: "grid grid-cols-4 w-full"
end
