defmodule Luminous.Live do
  @moduledoc """
  This module defines a macro that contains the functionality of a
  dashboard LiveView. It needs to be used (`use Luminous.Live`)
  inside a client application module with the appropriate options (as
  specified in `Luminous.Dashboard.define!/1`).

  More details and examples in the project README.
  """

  defmacro __using__(opts) do
    quote do
      use Phoenix.LiveView
      use Luminous.Dashboard

      defp __init__(), do: Luminous.Dashboard.define!(unquote(opts))

      @impl true
      def mount(_, _, socket) do
        dashboard = Luminous.Dashboard.populate(__init__(), socket.assigns)

        {:ok, assign(socket, dashboard: dashboard)}
      end

      @impl true
      def handle_params(params, _uri, socket) do
        socket =
          if connected?(socket) do
            # get time from params
            time_range = lmn_get_time_range(socket.assigns.dashboard, params)

            # get variable values from params
            variables =
              Enum.map(
                socket.assigns.dashboard.variables,
                &Luminous.Variable.update_current(&1, params["#{&1.id}"])
              )

            # update dashboard
            dashboard =
              socket.assigns.dashboard
              |> Luminous.Dashboard.update_variables(variables)
              |> Luminous.Dashboard.update_current_time_range(time_range)

            # refresh all panel data
            socket =
              Enum.reduce(dashboard.panels, socket, fn panel, sock ->
                Task.async(fn ->
                  {panel, Luminous.Panel.refresh(panel, variables, time_range)}
                end)

                lmn_push_panel_load_event(sock, :start, panel.id)
              end)

            socket
            |> assign(dashboard: dashboard)
            |> lmn_push_time_range_event(Luminous.TimeRangeSelector.id(), time_range)
          else
            socket
          end

        {:noreply, socket}
      end

      @impl true
      def handle_event(
            "lmn_time_range_change",
            %{"from" => from_iso, "to" => to_iso},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        time_range =
          Luminous.TimeRange.from_iso(from_iso, to_iso)
          |> Luminous.TimeRange.shift_zone!(dashboard.time_zone)

        url_params =
          Luminous.Dashboard.url_params(dashboard, from: time_range.from, to: time_range.to)

        {:noreply, push_patch(socket, to: dashboard_path(socket, url_params))}
      end

      def handle_event(
            "lmn_preset_time_range_selected",
            %{"preset" => preset},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        time_range =
          case Luminous.TimeRangeSelector.get_time_range_for(preset, dashboard.time_zone) do
            nil -> lmn_get_default_time_range(dashboard)
            time_range -> time_range
          end

        url_params =
          Luminous.Dashboard.url_params(dashboard, from: time_range.from, to: time_range.to)

        {:noreply, push_patch(socket, to: dashboard_path(socket, url_params))}
      end

      def handle_event(
            "lmn_variable_updated",
            %{"variable" => variable, "value" => value},
            %{assigns: %{dashboard: dashboard}} = socket
          ) do
        value = if value == [], do: "none", else: value

        url_params =
          Luminous.Dashboard.url_params(dashboard, [
            {String.to_existing_atom(variable), value}
          ])

        {:noreply, push_patch(socket, to: dashboard_path(socket, url_params))}
      end

      @impl true
      def handle_info({_task_ref, {%{type: type, id: id} = panel, datasets}}, socket) do
        panel_data = apply(type, :reduce, [datasets, panel, socket.assigns.dashboard])

        socket =
          socket
          |> assign(
            dashboard: Luminous.Dashboard.update_data(socket.assigns.dashboard, id, panel_data)
          )
          |> lmn_push_panel_load_event(:end, id)

        socket =
          if is_nil(panel.hook),
            do: socket,
            else: push_event(socket, "#{Luminous.Utils.dom_id(panel)}::refresh-data", panel_data)

        {:noreply, socket}
      end

      # this will be called each time a panel refresh async task terminates
      def handle_info({:DOWN, _task_ref, :process, _, _}, socket) do
        {:noreply, socket}
      end

      defp lmn_get_time_range(dashboard, %{"from" => from_unix, "to" => to_unix}) do
        Luminous.TimeRange.from_unix(
          String.to_integer(from_unix),
          String.to_integer(to_unix)
        )
        |> Luminous.TimeRange.shift_zone!(dashboard.time_zone)
      end

      defp lmn_get_time_range(dashboard, _), do: lmn_get_default_time_range(dashboard)

      defp lmn_get_default_time_range(dashboard) do
        if function_exported?(__MODULE__, :default_time_range, 1) do
          apply(__MODULE__, :default_time_range, [dashboard.time_zone])
        else
          Luminous.TimeRange.default(dashboard.time_zone)
        end
      end

      defp lmn_push_panel_load_event(socket, :start, panel_id),
        do: push_event(socket, "panel:load:start", %{id: panel_id})

      defp lmn_push_panel_load_event(socket, :end, panel_id),
        do: push_event(socket, "panel:load:end", %{id: panel_id})

      defp lmn_push_time_range_event(socket, time_range_selector_id, %Luminous.TimeRange{} = tr) do
        topic = "#{time_range_selector_id}::refresh-data"
        payload = %{time_range: Luminous.TimeRange.to_map(tr)}
        push_event(socket, topic, payload)
      end
    end
  end
end
