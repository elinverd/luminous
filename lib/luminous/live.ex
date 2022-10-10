defmodule Luminous.Live do
  @doc false
  defmacro __using__(dashboard: dashboard) do
    quote do
      use Phoenix.LiveView

      alias Luminous.{
        Dashboard,
        Components,
        Panel,
        Query,
        TimeRange,
        TimeRangeSelector,
        Variable,
        Helpers
      }

      require Logger

      defp dashboard(), do: unquote(dashboard)

      @impl true
      def mount(_, _, socket) do
        dashboard = Dashboard.populate(unquote(dashboard))

        {:ok,
         assign(socket,
           dashboard: dashboard,
           stats: %{},
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
      def handle_info({_task_ref, {%Panel{type: :chart} = panel, datasets}}, socket) do
        datasets = Enum.map(datasets, &Query.DataSet.maybe_override_unit(&1, panel.unit))

        panel_data = %{
          datasets: datasets,
          ylabel: panel.ylabel,
          xlabel: panel.xlabel,
          stacked_x: panel.stacked_x,
          stacked_y: panel.stacked_y,
          time_zone: socket.assigns.dashboard.time_zone
        }

        panel_statistics =
          Map.put(
            socket.assigns.panel_statistics,
            panel.id,
            Enum.map(datasets, &Query.DataSet.statistics/1)
          )

        socket =
          socket
          |> assign(panel_statistics: panel_statistics)
          |> push_event("#{Components.panel_id(panel)}::refresh-data", panel_data)
          |> push_panel_load_event(:end, panel.id)

        {:noreply, socket}
      end

      def handle_info({_task_ref, {%Panel{type: :stat} = panel, datasets}}, socket) do
        datasets = Enum.map(datasets, &Query.DataSet.maybe_override_unit(&1, panel.unit))

        new_stats = Map.put(socket.assigns.stats, panel.id, datasets)

        socket =
          socket
          |> assign(stats: new_stats)
          |> push_panel_load_event(:end, panel.id)

        {:noreply, socket}
      end

      # this will be called each time a panel refresh async task terminates
      @impl true
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

      @impl true
      def handle_event("time_range_change", %{"from" => from_iso, "to" => to_iso}, socket) do
        time_range =
          TimeRange.from_iso(from_iso, to_iso)
          |> TimeRange.shift_zone!(socket.assigns.dashboard.time_zone)

        dashboard = Dashboard.update_current_time_range(socket.assigns.dashboard, time_range)

        socket =
          socket
          |> assign(dashboard: dashboard)
          |> push_patch(
            to:
              Components.generate_link(socket, socket.assigns.dashboard,
                from: DateTime.to_unix(time_range.from),
                to: DateTime.to_unix(time_range.to)
              )
          )

        {:noreply, socket}
      end

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
