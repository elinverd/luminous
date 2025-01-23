defmodule Luminous.Components do
  @moduledoc """
  Phoenix function components for visualizing a dashboard and its constituent components.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Luminous.{TimeRangeSelector, Variable, Utils}

  @doc """
  This component is responsible for setting up various dashboard prerequisites
  """
  def setup(assigns) do
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
  The dashboard component is responsible for rendering all the necessary elements:
  - title
  - variables
  - time range selector
  - panels

  Additionally, it registers callbacks for reacting to panel loading states.
  """
  attr :dashboard, :map, required: true

  def dashboard(assigns) do
    ~H"""
    <.setup />
    <div class="relative mx-4 md:mx-8 lg:mx-auto max-w-screen-lg">
      <div class="py-4 z-10 flex flex-col space-y-4 sticky top-0 backdrop-blur-sm backdrop-grayscale opacity-100 ">
        <div class="pb-4 text-4xl text-center"><%= @dashboard.title %></div>
        <div class="flex flex-col md:flex-row justify-between space-y-1">
          <div class="flex space-x-1 md:space-x-2 items-center">
            <%= for var <- @dashboard.variables, !var.hidden do %>
              <.variable variable={var} />
            <% end %>
          </div>

          <div class="flex space-x-2 items-center">
            <.time_range time_zone={@dashboard.time_zone} />
          </div>
        </div>
      </div>

      <div class="z-0 flex flex-col w-full space-y-8">
        <%= for panel <- @dashboard.panels do %>
          <.panel panel={panel} dashboard={@dashboard} />
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  This component is responsible for rendering a `Panel` by rendering all the common panel elements
  and then delegating the rendering to the concrete `Panel`
  """
  attr :panel, :map, required: true
  attr :dashboard, :map, required: true

  def panel(assigns) do
    ~H"""
    <div class="flex flex-col items-center w-full space-y-4 md:shadow-lg md:px-4 py-6 bg-white">
      <div class="flex relative w-full justify-center">
        <div
          id={"#{@panel.id}-loading"}
          class="absolute top-0 left-0 hidden"
          role="status"
          phx-update="ignore"
        >
          <svg
            aria-hidden="true"
            class="mr-2 w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600"
            viewBox="0 0 100 101"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
              fill="currentColor"
            />
            <path
              d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
              fill="currentFill"
            />
          </svg>
          <span class="sr-only">Loading...</span>
        </div>

        <%= if has_panel_actions?(@panel) do %>
          <div
            id={"#{Utils.dom_id(@panel)}-actions"}
            class="absolute inline-block top-0 right-0"
            phx-click-away={hide_dropdown("#{Utils.dom_id(@panel)}-actions-dropdown")}
          >
            <div
              tabindex="0"
              class="w-6 h-6 cursor-pointer focus:outline-none"
              phx-click={show_dropdown("#{Utils.dom_id(@panel)}-actions-dropdown")}
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
                <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z" />
              </svg>
            </div>
            <div
              id={"#{Utils.dom_id(@panel)}-actions-dropdown"}
              class="absolute hidden right-0 lmn-panel-actions-dropdown"
            >
              <ul>
                <%= for %{event: event, label: label} <- get_panel_actions(@panel) do %>
                  <li class="lmn-panel-actions-dropdown-item-container">
                    <div
                      class="lmn-panel-actions-dropdown-item-content"
                      phx-click={
                        hide_dropdown("#{Utils.dom_id(@panel)}-actions-dropdown")
                        |> JS.dispatch("panel:#{Utils.dom_id(@panel)}:#{event}",
                          to: "##{Utils.dom_id(@panel)}"
                        )
                      }
                    >
                      <%= label %>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        <% end %>

        <div class="flex flex-row space-x-4">
          <div id={"#{Utils.dom_id(@panel)}-title"} class="text-xl font-medium">
            <%= interpolate(@panel.title, @dashboard.variables) %>
          </div>
          <%= unless is_nil(@panel.description) do %>
            <div class="flex flex-col items-center lmn-has-tooltip">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <div id={"lum-#{@panel.id}-tooltip"} class="lmn-tooltip translate-y-6">
                <%= @panel.description %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%= apply(@panel.type, :render, [assigns]) %>
    </div>
    """
  end

  defp has_panel_actions?(panel), do: panel |> get_panel_actions |> length > 0

  defp get_panel_actions(panel) do
    if function_exported?(panel.type, :actions, 0) do
      apply(panel.type, :actions, [])
    else
      []
    end
  end

  @doc """
  This component is responsible for rendering the `Luminous.TimeRange` component.
  It consists of a date range picker and a presets dropdown.
  """
  attr :time_zone, :string, required: true
  attr :presets, :list, required: false, default: nil
  attr :class, :string, required: false, default: ""

  def time_range(assigns) do
    presets =
      if is_nil(assigns.presets), do: Luminous.TimeRangeSelector.presets(), else: assigns.presets

    assigns = assign(assigns, presets: presets)

    ~H"""
    <div class={"lmn-time-range-compound #{@class}"}>
      <div class="lmn-time-range-selector">
        <!-- Date picker -->
        <input
          id={TimeRangeSelector.id()}
          phx-hook={TimeRangeSelector.hook()}
          phx-update="ignore"
          readonly="readonly"
          class="lmn-custom-time-range-input"
        />
        <!-- Presets button & dropdown -->
        <div class="relative flex items-center" phx-click-away={hide_dropdown("preset-dropdown")}>
          <button class="lmn-time-range-presets-button" phx-click={show_dropdown("preset-dropdown")}>
            <svg
              class="lmn-time-range-presets-button-icon"
              id="chevron-down"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
          <div id="preset-dropdown" class="absolute hidden top-10 right-0">
            <ul class="lmn-time-range-presets-dropdown">
              <%= for preset <- @presets do %>
                <li class="lmn-time-range-presets-dropdown-item-container">
                  <div
                    class="lmn-time-range-presets-dropdown-item-content"
                    id={"time-range-preset-#{preset}"}
                    phx-click={
                      hide_dropdown("preset-dropdown")
                      |> JS.push("lmn_preset_time_range_selected")
                    }
                    phx-value-preset={preset}
                  >
                    <%= preset %>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>
      <div class="lmn-time-zone">
        <%= @time_zone |> DateTime.now!() |> Calendar.strftime("%Z") %>
      </div>
    </div>
    """
  end

  @doc """
  This component is responsible for rendering the dropdown of the assigned `Variable`.
  """
  attr :variable, :map, required: true

  def variable(%{variable: %{type: :single}} = assigns) do
    ~H"""
    <div
      id={"#{@variable.id}-dropdown"}
      class="relative"
      phx-click-away={hide_dropdown("#{@variable.id}-dropdown-content")}
    >
      <button
        class="lmn-variable-button"
        phx-click={show_dropdown("#{@variable.id}-dropdown-content")}
      >
        <div id={"#{@variable.id}-dropdown-label"} class="lmn-variable-button-label">
          <span class="lmn-variable-button-label-prefix"><%= "#{@variable.label}: " %></span><%= Variable.get_current_label(
            @variable
          ) %>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="lmn-variable-button-icon"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        </svg>
      </button>
      <!-- Dropdown content -->
      <div id={"#{@variable.id}-dropdown-content"} class="absolute hidden">
        <ul class="lmn-variable-dropdown">
          <%= for %{label: label, value: value} <- @variable.values do %>
            <li class="lmn-variable-dropdown-item-container">
              <div
                id={"#{@variable.id}-#{value}"}
                class="lmn-variable-dropdown-item-content"
                phx-click={
                  hide_dropdown("#{@variable.id}-dropdown-content")
                  |> JS.push("lmn_variable_updated")
                }
                phx-value-variable={"#{@variable.id}"}
                phx-value-value={"#{value}"}
              >
                <%= label %>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def variable(%{variable: %{type: :multi}} = assigns) do
    ~H"""
    <div
      id={"#{@variable.id}-dropdown"}
      class="relative"
      phx-hook="MultiSelectVariableHook"
      phx-click-away={
        hide_dropdown("#{@variable.id}-dropdown-content")
        |> JS.dispatch("clickAway", detail: %{"var_id" => @variable.id})
      }
    >
      <button
        class="lmn-variable-button"
        phx-click={
          show_dropdown("#{@variable.id}-dropdown-content")
          |> JS.dispatch("dropdownOpen",
            detail: %{"values" => Variable.extract_value(@variable.current)}
          )
        }
      >
        <div id={"#{@variable.id}-dropdown-label"} class="lmn-variable-button-label">
          <span class="lmn-variable-button-label-prefix"><%= "#{@variable.label}: " %></span><%= Variable.get_current_label(
            @variable
          ) %>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="lmn-variable-button-icon"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        </svg>
      </button>
      <!-- Dropdown content -->
      <div id={"#{@variable.id}-dropdown-content"} class="lmn-multi-variable-dropdown-container">
        <div :if={Variable.show_search?(@variable)}>
          <div class="lmn-multi-variable-dropdown-searchbox">
            <input
              id={"#{@variable.id}-dropdown-search-input"}
              type="text"
              placeholder={"Search #{String.downcase(@variable.label)}..."}
              class="lmn-multi-variable-dropdown-search-input"
              autocomplete="off"
              phx-change={
                JS.dispatch("itemSearch",
                  detail: %{
                    "input_id" => "#{@variable.id}-dropdown-search-input",
                    "list_id" => "#{@variable.id}-items-list"
                  }
                )
              }
            />
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="lmn-multi-variable-dropdown-search-icon"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
              />
            </svg>
          </div>
          <button
            phx-click={
              JS.dispatch("clearSelection", detail: %{"list_id" => "#{@variable.id}-items-list"})
            }
            class="lmn-multi-variable-dropdown-search-clear"
          >
            Clear selection
          </button>
        </div>
        <ul id={"#{@variable.id}-items-list"} class="flex flex-col max-h-96 overflow-auto mt-2">
          <li
            :for={%{label: label, value: value} <- @variable.values}
            class="inline-block w-max"
            id={"#{@variable.id}-#{label}"}
          >
            <label
              for={"#{@variable.id}-#{value}-checkbox"}
              class="lmn-multi-variable-dropdown-item-container"
            >
              <input
                type="checkbox"
                id={"#{@variable.id}-#{value}-checkbox"}
                phx-click={JS.dispatch("valueClicked", detail: %{"value" => value})}
                class="lmn-multi-variable-dropdown-checkbox"
                checked={value in Variable.extract_value(@variable.current)}
              />
              <span class="select-none"><%= label %></span>
            </label>
          </li>
        </ul>
      </div>
    </div>
    """
  end

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

  # Interpolate all occurences of variable IDs in the format `$variable.id` in the string
  # with the variable's descriptive value label. For example, the string: "Energy for asset $asset_var"
  # will be replaced by the label of the variable with id `:asset_var` in variables.
  defp interpolate(nil, _), do: ""

  defp interpolate(string, variables) do
    Enum.reduce(variables, string, fn var, title ->
      String.replace(title, "$#{var.id}", "#{Variable.get_current_label(var)}")
    end)
  end
end
