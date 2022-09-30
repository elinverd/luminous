defimpl Phoenix.HTML.Safe, for: Decimal do
  def to_iodata(data), do: Decimal.to_string(data)
end

defmodule Luminous.Components do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias Luminous.{Dashboard, Helpers}

  @doc """
  the dashboard component is responsible for rendering all the necessary elements:
  - title
  - variables
  - time range selector
  - panels

  it also registers callbacks for reacting to panel loading states
  """
  def dashboard(
        %{dashboard: dashboard, stats: stats, panel_statistics: panel_statistics, socket: socket} =
          assigns
      ) do
    ~H"""
    <.listeners />
    <div class="relative mx-8 lg:mx-auto max-w-screen-lg">
      <div class="py-4 z-10 flex flex-col space-y-4 sticky top-0 backdrop-blur-sm backdrop-grayscale opacity-100 ">

        <div class="pb-4 text-4xl font-bold text-center "><%= dashboard.title %></div>
        <div class="flex flex-col md:flex-row justify-between">
          <div class="flex space-x-2 items-center">
            <%= for var <- dashboard.variables do %>
            <.variable variable={var} link_fun={generate_link_fun(socket, dashboard)} />
            <% end %>
          </div>

          <div class="flex space-x-2 items-center">
            <.time_range dashboard={dashboard}, link_fun={generate_link_fun(socket, dashboard)} />
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

        <div id={"#{panel_id(panel)}-actions"} class="dropdown dropdown-end absolute inline-block top-0 right-0" x-data="{open: false}">
          <div tabindex="0" class="w-6 h-6" @click="open = true"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/></svg>
          </div>
          <ul x-show="open" tabindex="0" class="menu dropdown-content p-2 shadow bg-base-100 text-sm rounded-box w-48 mt-4">
            <li>
              <button phx-click={JS.dispatch("panel:#{panel_id(panel)}:download:csv", to: "##{panel_id(panel)}")} @click="open = false">
                Download CSV
              </button>
            </li>
            <li>
              <button phx-click={JS.dispatch("panel:#{panel_id(panel)}:download:png", to: "##{panel_id(panel)}")} @click="open = false">
                Download image
              </button>
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

        <div class="flex flex-row space-x-4">
          <div id={"#{panel_id(panel)}-title"} class="text-xl font-medium"><%= Helpers.interpolate(panel.title, variables) %></div>
          <.description description={panel.description}/>
        </div>
      </div>

      <div class="w-full">
        <%= if stat_data = stats[panel.id] do %>
          <div id={"#{panel_id(panel)}-stat-values"} class="flex flex-row items-center justify-center ">
            <%= for stat <- stat_data.values do %>
              <div class="flex flex-col items-center">
                <%= if is_nil(stat) do %>
                  <span class="text-4xl font-bold">-</span>
                <% else %>
                  <div><span class="text-4xl font-bold"><%= stat %></span> <span class="text-2xl font-semibold"><%= stat_data.unit %></span></div>
                <% end %>

                <%= unless is_nil(stat_data.ylabel) do %>
                  <div class="text-sm"><%= stat_data.ylabel %></div>
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
        <div><%= var.min %></div>
        <div><%= var.max %></div>
        <div><%= var.avg %></div>
        <div><%= var.sum %></div>
      <% end %>
    </div>
    """
  end

  def time_range(%{dashboard: dashboard, link_fun: link_fun} = assigns) do
    ~H"""
      <div class="btn btn-ghost no-animation cursor-default space-x-4 px-0 hover:bg-transparent">
        <div class="flex items-center outline outline-1 rounded-lg ">
          <input id={dashboard.time_range_selector.id} phx-hook={dashboard.time_range_selector.hook} phx-update="ignore" readonly="readonly" class="w-52 btn btn-sm btn-outline border-0 rounded-r-none focus:outline-none" />
          <div class="dropdown dropdown-end" x-data="{open: false}">
            <label tabindex="0" class="btn btn-sm btn-outline border-0 px-1 rounded-l-none" @click="open = true">
              <svg id="chevron-down" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </label>
            <ul x-show="open" id="preset-dropdown" tabindex="0" class="p-2 shadow menu dropdown-content bg-base-100 rounded-box min-w-max overflow-auto normal-case font-normal text-base">
              <%= for preset <- dashboard.time_range_presets do %>
              <li>
                <%= live_patch preset.label, to: link_fun.(from: DateTime.to_unix(preset.value.from), to: DateTime.to_unix(preset.value.to)), "@click": "open = false" %>
              </li>
              <% end %>
            </ul>
          </div>
        </div>
        <div class="badge badge-primary cursor-default font-bold ">
          <%= dashboard.time_zone |> DateTime.now!() |> Calendar.strftime("%Z") %>
        </div>
      </div>
    """
  end

  def variable(%{variable: variable, link_fun: link_fun} = assigns) do
    ~H"""
      <.dropdown
        id={"#{variable.id}-dropdown"}
        value={variable.current.label} description={variable.label}
        items={variable.values}
        let={%{label: label, value: value}}>
        <%= live_patch label, to: link_fun.("#{variable.id}": value) %>
      </.dropdown>
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

  def dropdown(%{value: value, description: description, id: id, items: items} = assigns)
      when is_binary(value) and is_binary(description) and is_binary(id) and is_list(items) do
    ~H"""
    <div id={id} class="dropdown" x-data="{open: false}">
      <label tabindex="0" class="btn btn-outline btn-sm gap-2 flex-nowrap" @click="open = true">
        <span class="text-left text-ellipsis whitespace-nowrap overflow-hidden max-w-xs">
          <span class="text-xs"><%= "#{description}: " %></span><%= @value %>
        </span>
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </label>
      <ul x-show="open" tabindex="0" class="p-2 shadow menu dropdown-content bg-base-100 rounded-box min-w-max max-h-96 overflow-auto">
        <%= for item <- @items do %>
          <li class="text-left" @click="open = false">
            <%= render_slot(@inner_block, item) %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def generate_link_fun(socket, dashboard) do
    fn opts -> generate_link(socket, dashboard, opts) end
  end

  def generate_link(socket, dashboard, opts) do
    var_args =
      Enum.map(dashboard.variables, fn var ->
        {var.id, Keyword.get(opts, var.id, var.current.value)}
      end)

    time_range_args = [
      from:
        Keyword.get(
          opts,
          :from,
          DateTime.to_unix(dashboard.time_range_selector.current_time_range.from)
        ),
      to:
        Keyword.get(
          opts,
          :to,
          DateTime.to_unix(dashboard.time_range_selector.current_time_range.to)
        )
    ]

    Dashboard.path(dashboard, socket, Keyword.merge(var_args, time_range_args))
  end

  def panel_id(panel), do: "panel-#{panel.id}"
end
