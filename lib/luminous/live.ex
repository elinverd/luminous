defmodule Luminous.Live do
  @moduledoc """
  This module contains a macro that contains the functionality of a dashboard LiveView.
  For more information see `Luminous.Dashboards.DemoDashboardLive`.
  """

  defmacro __using__(dashboard: dashboard) do
    quote do
      use Phoenix.LiveView

      @behaviour Luminous.Dashboard

      alias Luminous.{
        Dashboard,
        Components,
        Panel,
        Query,
        TimeRange,
        TimeRangeSelector,
        Variable
      }

      require Logger

      defp dashboard(), do: unquote(dashboard)

      @impl true
      def mount(_, _, socket) do
        params =
          if function_exported?(__MODULE__, :parameters, 1) do
            apply(__MODULE__, :parameters, [socket])
          else
            %{}
          end

        dashboard = Dashboard.populate(dashboard(), params)

        {:ok,
         assign(socket,
           dashboard: dashboard,
           panel_data: %{},
           panel_statistics: %{}
         )}
      end

      @impl true
      def handle_params(params, _uri, socket) do
        if connected?(socket) do
          # get time from params
          time_range = get_time_range(socket.assigns.dashboard, params)

          # get variable values from params
          variables =
            socket.assigns.dashboard.variables
            |> Enum.map(fn var ->
              if new_val = params["#{var.id}"] do
                Variable.update_current(var, new_val)
              else
                var
              end
            end)

          # update dashboard
          dashboard =
            socket.assigns.dashboard
            |> Dashboard.update_variables(variables)
            |> Dashboard.update_current_time_range(time_range)

          # refresh all panel data
          socket =
            Enum.reduce(dashboard.panels, socket, fn panel, sock ->
              Task.async(fn ->
                {panel, Panel.refresh(panel, variables, time_range)}
              end)

              push_panel_load_event(sock, :start, panel.id)
            end)

          socket =
            socket
            |> assign(dashboard: dashboard)
            |> push_time_range_event(dashboard.time_range_selector.id, time_range)

          {:noreply, socket}
        else
          {:noreply, socket}
        end
      end

      @impl true
      def handle_event(
            "time_range_change",
            %{"from" => from_iso, "to" => to_iso},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        time_range =
          TimeRange.from_iso(from_iso, to_iso)
          |> TimeRange.shift_zone!(dashboard.time_zone)

        {:noreply,
         push_patch(socket,
           to: Dashboard.path(dashboard, socket, from: time_range.from, to: time_range.to)
         )}
      end

      def handle_event(
            "preset_time_range_selected",
            %{"preset" => preset},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        time_range =
          TimeRangeSelector.get_time_range_for(
            dashboard.time_range_selector,
            preset,
            dashboard.time_zone
          )

        {:noreply,
         push_patch(socket,
           to: Dashboard.path(dashboard, socket, from: time_range.from, to: time_range.to)
         )}
      end

      def handle_event(
            "variable_updated",
            %{"variable" => variable, "value" => value},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        {:noreply,
         push_patch(socket,
           to: Dashboard.path(dashboard, socket, [{String.to_existing_atom(variable), value}])
         )}
      end

      @impl true
      def handle_info({_task_ref, {%Panel{type: :chart} = panel, datasets}}, socket) do
        panel_data = %{
          datasets: datasets,
          ylabel: panel.ylabel,
          xlabel: panel.xlabel,
          stacked_x: panel.stacked_x,
          stacked_y: panel.stacked_y,
          time_zone: socket.assigns.dashboard.time_zone
        }

        socket =
          socket
          |> assign(panel_data: Map.put(socket.assigns.panel_data, panel.id, panel_data))
          |> push_event("#{Panel.dom_id(panel)}::refresh-data", panel_data)
          |> push_panel_load_event(:end, panel.id)

        {:noreply, socket}
      end

      def handle_info({_task_ref, {%Panel{type: :stat} = panel, dataset}}, socket) do
        socket =
          socket
          |> assign(panel_data: Map.put(socket.assigns.panel_data, panel.id, dataset))
          |> push_panel_load_event(:end, panel.id)

        {:noreply, socket}
      end

      # a table can have only one dataset
      def handle_info(
            {_task_ref, {%Panel{type: :table} = panel, datasets}},
            socket
          ) do
        socket =
          socket
          |> push_event("#{Panel.dom_id(panel)}::refresh-data", hd(datasets))
          |> push_panel_load_event(:end, panel.id)

        {:noreply, socket}
      end

      # this will be called each time a panel refresh async task terminates
      def handle_info({:DOWN, _task_ref, :process, _, _}, socket) do
        {:noreply, socket}
      end

      defp get_time_range(dashboard, %{"from" => from_unix, "to" => to_unix}) do
        TimeRange.from_unix(
          String.to_integer(from_unix),
          String.to_integer(to_unix)
        )
        |> TimeRange.shift_zone!(dashboard.time_zone)
      end

      defp get_time_range(dashboard, _), do: Dashboard.default_time_range(dashboard)

      defp push_panel_load_event(socket, :start, panel_id),
        do: push_event(socket, "panel:load:start", %{id: panel_id})

      defp push_panel_load_event(socket, :end, panel_id),
        do: push_event(socket, "panel:load:end", %{id: panel_id})

      defp push_time_range_event(socket, time_range_selector_id, %TimeRange{} = tr) do
        topic = "#{time_range_selector_id}::refresh-data"
        payload = %{time_range: TimeRange.to_map(tr)}
        push_event(socket, topic, payload)
      end
    end
  end
end
