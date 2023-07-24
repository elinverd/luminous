defmodule Luminous.Components do
  @moduledoc """
  This module contains a set of components that can be used to create a dashboard.
  """

  use Phoenix.Component
  alias Luminous.TimeRangeSelector
  alias Luminous.Dashboard
  alias Phoenix.LiveView.JS

  alias Luminous.{Panel, Variable}

  @doc """
  The dashboard component is responsible for rendering all the necessary elements:
  - title
  - variables
  - time range selector
  - panels

  Additinally, it registers callbacks for reacting to panel loading states.
  """
  attr :dashboard, Dashboard, required: true
  attr :panel_data, :map, required: true

  def dashboard(assigns) do
    ~H"""
    <.listeners />
    <div class="relative mx-8 lg:mx-auto max-w-screen-lg">
      <div class="py-4 z-10 flex flex-col space-y-4 sticky top-0 backdrop-blur-sm backdrop-grayscale opacity-100 ">

        <div class="pb-4 text-4xl font-bold text-center "><%= @dashboard.title %></div>
        <div class="flex flex-col md:flex-row justify-between">
          <div class="flex space-x-2 items-center">
            <%= for var <- @dashboard.variables do %>
              <.variable variable={var} />
            <% end %>
          </div>

          <div class="flex space-x-2 items-center">
            <.time_range dashboard={@dashboard} />
          </div>
        </div>
      </div>

      <div class="z-0 flex flex-col w-full space-y-8">
        <%= for panel <- @dashboard.panels do %>
          <.panel panel={panel} panel_data={@panel_data} variables={@dashboard.variables} time_range_selector={@dashboard.time_range_selector} />
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  This component registers the JS event listeners for the panel spinners.
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
  This component is responsible for rendering the panel's data.
  Depending on the panel's type, there will be a different visualization.
  """
  attr :panel, Panel, required: true
  attr :variables, :list, required: true
  attr :panel_data, :map, required: false, doc: "not used in table panel"

  attr :time_range_selector, TimeRangeSelector,
    required: false,
    doc: "only for the chart panel"

  def panel(%{panel: %{type: :chart}} = assigns) do
    time_range_selector_id =
      assigns
      |> Map.get(:time_range_selector, %{})
      |> Map.get(:id)

    assigns = assign(assigns, time_range_selector_id: time_range_selector_id)

    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 shadow-lg px-4 py-6 bg-white">
      <div class="flex relative w-full justify-center">
        <div id={"#{@panel.id}-loading"} class="absolute inline-block top-0 left-0 hidden" role="status" phx-update="ignore">
          <svg aria-hidden="true" class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
            <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <div id={"#{Panel.dom_id(@panel)}-actions"} class="absolute inline-block top-0 right-0" phx-click-away={hide_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown")}>
          <div tabindex="0" class="w-6 h-6 cursor-pointer focus:outline-none" phx-click={show_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown")}>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
              <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/>
            </svg>
          </div>
          <div id={"#{Panel.dom_id(@panel)}-actions-dropdown"} class="absolute hidden right-0">
            <ul class="lmn-panel-actions-dropdown">
              <li class="lmn-panel-actions-dropdown-item-container">
                <div class="lmn-panel-actions-dropdown-item-content" phx-click={hide_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown") |> JS.dispatch("panel:#{Panel.dom_id(@panel)}:download:csv", to: "##{Panel.dom_id(@panel)}")}>
                  Download CSV
                </div>
              </li>
              <li class="lmn-panel-actions-dropdown-item-container">
                <div class="lmn-panel-actions-dropdown-item-content" phx-click={hide_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown") |> JS.dispatch("panel:#{Panel.dom_id(@panel)}:download:png", to: "##{Panel.dom_id(@panel)}")}>
                  Download image
                </div>
              </li>
            </ul>
          </div>
        </div>

        <div class="flex flex-row space-x-4">
          <div id={"#{Panel.dom_id(@panel)}-title"} class="text-xl font-medium"><%= interpolate(@panel.title, @variables) %></div>
          <.description panel={@panel}/>
        </div>
      </div>

      <div class="w-full ">
        <div id={"#{Panel.dom_id(@panel)}-container"} phx-update="ignore">
          <canvas id={Panel.dom_id(@panel)} time-range-selector-id={TimeRangeSelector.id()} phx-hook={@panel.hook}></canvas>
        </div>
        <%= if data = @panel_data[@panel.id] do %>
          <.panel_statistics stats={Enum.map(data.datasets, & &1.stats)}/>
        <% end %>
      </div>
    </div>
    """
  end

  def panel(%{panel: %{type: :stat}} = assigns) do
    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 shadow-lg px-4 py-6 bg-white">
      <div class="flex relative w-full justify-center">
        <div id={"#{@panel.id}-loading"} class="absolute inline-block top-0 left-0 hidden" role="status" phx-update="ignore">
          <svg aria-hidden="true" class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
            <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <%= if @panel.title != "" or @panel.description != "" do %>
          <div class="flex flex-row space-x-4">
            <div id={"#{Panel.dom_id(@panel)}-title"} class="text-xl font-medium"><%= interpolate(@panel.title, @variables) %></div>
            <.description panel={@panel}/>
          </div>
        <% end %>
      </div>

      <% dataset = @panel_data[@panel.id] %>

      <%= if dataset && length(dataset) > 0 do %>
        <div id={"#{Panel.dom_id(@panel)}-stat-values"} class={stats_grid_structure(length(dataset))}>
          <%= for column <- dataset do %>
          <div class="flex flex-col items-center">
            <div class="text-lg"><%= column.title %></div>
            <div><span class="text-4xl font-bold"><%= print_number(column.value) %></span> <span class="text-2xl font-semibold"><%= column.unit %></span></div>

          </div>
          <% end %>
        </div>
      <% else %>
        <div class="flex flex-row items-center justify-center">
          <div id={"#{Panel.dom_id(@panel)}-stat-values"} class="text-4xl font-bold">-</div>
        </div>
      <% end %>
    </div>
    """
  end

  def panel(%{panel: %{type: :table}} = assigns) do
    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 shadow-lg px-4 py-6 bg-white">
      <div class="flex relative w-full justify-center">
        <div id={"#{@panel.id}-loading"} class="absolute inline-block top-0 left-0 hidden" role="status" phx-update="ignore">
          <svg aria-hidden="true" class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
            <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <div id={"#{Panel.dom_id(@panel)}-actions"} class="absolute inline-block top-0 right-0 z-10" phx-click-away={hide_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown")}>
          <div tabindex="0" class="w-6 h-6 cursor-pointer focus:outline-none" phx-click={show_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown")}>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
              <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/>
            </svg>
          </div>
          <div id={"#{Panel.dom_id(@panel)}-actions-dropdown"} class="absolute hidden right-0">
            <ul class="lmn-panel-actions-dropdown">
              <li class="lmn-panel-actions-dropdown-item-container">
                <div class="lmn-panel-actions-dropdown-item-content" phx-click={hide_dropdown("#{Panel.dom_id(@panel)}-actions-dropdown") |> JS.dispatch("panel:#{Panel.dom_id(@panel)}:download:csv", to: "##{Panel.dom_id(@panel)}")}>
                  Download CSV
                </div>
              </li>
            </ul>
          </div>
        </div>

        <div class="flex flex-row space-x-4">
          <div id={"#{Panel.dom_id(@panel)}-title"} class="text-xl font-medium"><%= interpolate(@panel.title, @variables) %></div>
          <.description panel={@panel}/>
        </div>
      </div>

      <div class="w-full z-0">
        <div id={"#{Panel.dom_id(@panel)}"} phx-hook={@panel.hook} phx-update="ignore" />
      </div>
    </div>
    """
  end

  @doc """
  This component is responsible for rendering the time range component.
  It consists of a date range picker and a presets dropdown.
  """
  attr :dashboard, Dashboard, required: true

  def time_range(assigns) do
    ~H"""
      <div class="lmn-time-range-compound">
        <div class="lmn-time-range-selector">
          <!-- Date picker -->
          <input id={TimeRangeSelector.id()}
            phx-hook={TimeRangeSelector.hook()}
            phx-update="ignore" readonly="readonly"
            class="lmn-custom-time-range-input" />
          <!-- Presets button & dropdown -->
          <div class="relative" phx-click-away={hide_dropdown("preset-dropdown")}>
            <button class="lmn-time-range-presets-button" phx-click={show_dropdown("preset-dropdown")}>
              <svg class="lmn-time-range-presets-button-icon" id="chevron-down" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </button>
            <div id="preset-dropdown" class="absolute hidden top-10 right-0">
              <ul class="lmn-time-range-presets-dropdown">
                <%= for preset <- Luminous.TimeRangeSelector.presets() do %>
                  <li class="lmn-time-range-presets-dropdown-item-container">
                    <div class="lmn-time-range-presets-dropdown-item-content" id={"time-range-preset-#{preset}"}
                      phx-click={hide_dropdown("preset-dropdown") |> JS.push("preset_time_range_selected")}
                      phx-value-preset={preset}>
                      <%= preset %>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
        <div class="lmn-time-zone">
          <%= @dashboard.time_zone |> DateTime.now!() |> Calendar.strftime("%Z") %>
        </div>
      </div>
    """
  end

  @doc """
  This component is responsible for rendering the dropdown of the assigned variable.
  """
  attr :variable, Variable, required: true

  def variable(assigns) do
    ~H"""
    <div id={"#{@variable.id}-dropdown"} class="relative" phx-click-away={hide_dropdown("#{@variable.id}-dropdown-content")}>
      <button class="lmn-variable-button" phx-click={show_dropdown("#{@variable.id}-dropdown-content")}>
        <div class="lmn-variable-button-label">
          <span class="lmn-variable-button-label-prefix"><%= "#{@variable.label}: " %></span><%= @variable.current.label %>
        </div>
        <svg xmlns="http://www.w3.org/2000/svg" class="lmn-variable-button-icon" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      </button>
      <!-- Dropdown content -->
      <div id={"#{@variable.id}-dropdown-content"} class="absolute hidden">
        <ul class="lmn-variable-dropdown">
          <%= for %{label: label, value: value} <- @variable.values do %>
            <li class="lmn-variable-dropdown-item-container">
              <div id={"#{@variable.id}-#{value}"} class="lmn-variable-dropdown-item-content"
                phx-click={hide_dropdown("#{@variable.id}-dropdown-content") |> JS.push("variable_updated")}
                phx-value-variable={"#{@variable.id}"} phx-value-value={"#{value}"}>
                <%= label %>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  # Interpolate all occurences of variable IDs in the format `$variable.id` in the string
  # with the variable's descriptive value label. For example, the string: "Energy for asset $asset_var"
  # will be replaced by the label of the variable with id `:asset_var` in variables.
  @spec interpolate(binary(), [Variable.t()]) :: binary()
  defp interpolate(string, variables) do
    variables
    |> Enum.reduce(string, fn var, title ->
      val =
        var
        |> Variable.get_current()
        |> Variable.extract_label()

      String.replace(title, "$#{var.id}", "#{val}")
    end)
  end

  attr :stats, :map, required: true
  def panel_statistics(%{stats: nil} = assigns), do: ~H""

  def panel_statistics(%{stats: statistics} = assigns) when length(statistics) == 0,
    do: ~H""

  def panel_statistics(assigns) do
    ~H"""
    <div class="grid grid-cols-10 gap-x-4 mt-2 mx-8 text-right text-xs">
      <div class="col-span-5 text-xs font-semibold"></div>
      <div class="font-semibold">N</div>
      <div class="font-semibold">Min</div>
      <div class="font-semibold">Max</div>
      <div class="font-semibold">Avg</div>
      <div class="font-semibold">Total</div>

      <%= for var <- @stats do %>
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

  attr :panel, Panel, required: true
  def description(%{panel: %{description: nil}} = assigns), do: ~H""

  def description(assigns) do
    ~H"""
    <div class="flex flex-col items-center lmn-has-tooltip">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div id={"lum-#{@panel.id}-tooltip"} class="lmn-tooltip translate-y-6">
        <%= @panel.description %>
      </div>
    </div>
    """
  end

  defp print_number(n) do
    case n do
      %Decimal{} = n -> Decimal.to_string(n)
      nil -> "-"
      _ -> n
    end
  end

  defp stats_grid_structure(1), do: "grid grid-cols-1 w-full"
  defp stats_grid_structure(2), do: "grid grid-cols-2 w-full"
  defp stats_grid_structure(3), do: "grid grid-cols-3 w-full"
  defp stats_grid_structure(_), do: "grid grid-cols-4 w-full"

  defp show_dropdown(dropdown_id) do
    JS.show(
      to: "##{dropdown_id}",
      transition:
        {"lmn-dropdown-transition-enter", "lmn-dropdown-transition-start",
         "lmn-dropdown-transition-end"}
    )
  end

  defp hide_dropdown(dropdown_id) do
    JS.hide(to: "##{dropdown_id}")
  end
end
