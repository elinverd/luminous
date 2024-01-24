defmodule Luminous.Panel.Chart do
  alias Luminous.{Attributes, Panel, Utils}

  use Panel

  @impl true
  def data_attributes(),
    do: [
      type: [type: :atom, default: :line],
      fill: [type: :boolean, default: true],
      order: [type: :non_neg_integer, default: 0]
    ]

  @impl true
  def panel_attributes(),
    do: [
      xlabel: [type: :string, default: ""],
      ylabel: [type: :string, default: ""],
      stacked_x: [type: :boolean, default: false],
      stacked_y: [type: :boolean, default: false],
      y_min_value: [type: {:or, [:integer, :float, nil]}, default: nil],
      y_max_value: [type: {:or, [:integer, :float, nil]}, default: nil],
      hook: [type: :string, default: "ChartJSHook"]
    ]

  @impl true
  def transform(data, panel) when is_list(data) do
    # first, let's see if there's a specified ordering in var attrs
    order =
      Enum.reduce(panel.data_attributes, %{}, fn {label, attrs}, acc ->
        Map.put(acc, label, attrs.order)
      end)

    data
    |> extract_labels()
    |> Enum.map(fn label ->
      data =
        Enum.map(data, fn row ->
          {x, y} =
            case row do
              # row is a list of {label, value} tuples
              l when is_list(l) ->
                x =
                  case Keyword.get(row, :time) do
                    %DateTime{} = time -> DateTime.to_unix(time, :millisecond)
                    _ -> nil
                  end

                y =
                  Enum.find_value(l, fn
                    {^label, value} -> value
                    _ -> nil
                  end)

                {x, y}

              # row is a map where labels map to values
              m when is_map(m) ->
                x =
                  case Map.get(row, :time) do
                    %DateTime{} = time -> DateTime.to_unix(time, :millisecond)
                    _ -> nil
                  end

                {x, Map.get(m, label)}

              # row is a single number
              n when is_number(n) ->
                {nil, n}

              _ ->
                raise "Can not process data row #{inspect(row)}"
            end

          case {x, y} do
            {nil, y} -> %{y: convert_to_decimal(y)}
            {x, y} -> %{x: x, y: convert_to_decimal(y)}
          end
        end)
        |> Enum.reject(&is_nil(&1.y))

      attrs =
        Map.get(panel.data_attributes, label) ||
          Map.get(panel.data_attributes, to_string(label)) ||
          Attributes.parse!([], data_attributes() ++ Attributes.Data.common())

      %{
        rows: data,
        label: to_string(label),
        attrs: attrs,
        stats: statistics(data, to_string(label))
      }
    end)
    |> Enum.sort_by(fn dataset -> order[dataset.label] end)
  end

  @impl true
  def reduce(datasets, panel, dashboard) do
    %{
      datasets: datasets,
      ylabel: panel.ylabel,
      xlabel: panel.xlabel,
      stacked_x: panel.stacked_x,
      stacked_y: panel.stacked_y,
      y_min_value: panel.y_min_value,
      y_max_value: panel.y_max_value,
      time_zone: dashboard.time_zone
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full ">
        <div id={"#{Utils.dom_id(@panel)}-container"} phx-update="ignore">
          <canvas id={Utils.dom_id(@panel)} time-range-selector-id={@time_range_selector.id} phx-hook={@panel.hook}></canvas>
        </div>
        <%= unless is_nil(@data) do %>
          <.panel_statistics stats={Enum.map(@data.datasets, & &1.stats)}/>
        <% end %>
      </div>
    """
  end

  @impl true
  def actions() do
    [
      %{event: "download:csv", label: "Download CSV"},
      %{event: "download:png", label: "Download Image"}
    ]
  end

  def statistics(rows, label) do
    init_stats = %{n: 0, sum: nil, min: nil, max: nil, max_decimal_digits: 0}

    stats =
      Enum.reduce(rows, init_stats, fn %{y: y}, stats ->
        min = Map.fetch!(stats, :min) || y
        max = Map.fetch!(stats, :max) || y
        sum = Map.fetch!(stats, :sum)
        n = Map.fetch!(stats, :n)
        max_decimal_digits = Map.fetch!(stats, :max_decimal_digits)

        new_sum =
          case {sum, y} do
            {nil, y} -> y
            {sum, nil} -> sum
            {sum, y} -> Decimal.add(y, sum)
          end

        decimal_digits =
          with y when not is_nil(y) <- y,
               [_, dec] <- Decimal.to_string(y, :normal) |> String.split(".") do
            String.length(dec)
          else
            _ -> 0
          end

        stats
        |> Map.put(:min, if(!is_nil(y) && Decimal.lt?(y, min), do: y, else: min))
        |> Map.put(:max, if(!is_nil(y) && Decimal.gt?(y, max), do: y, else: max))
        |> Map.put(:sum, new_sum)
        |> Map.put(:n, if(is_nil(y), do: n, else: n + 1))
        |> Map.put(
          :max_decimal_digits,
          if(decimal_digits > max_decimal_digits, do: decimal_digits, else: max_decimal_digits)
        )
      end)

    # we use this to determine the rounding for the average dataset value
    max_decimal_digits = Map.fetch!(stats, :max_decimal_digits)

    # calculate the average
    avg =
      cond do
        stats[:n] == 0 ->
          nil

        is_nil(stats[:sum]) ->
          nil

        true ->
          Decimal.div(stats[:sum], Decimal.new(stats[:n])) |> Decimal.round(max_decimal_digits)
      end

    stats
    |> Map.put(:avg, avg)
    |> Map.put(:label, label)
    |> Map.delete(:max_decimal_digits)
  end

  defp convert_to_decimal(nil), do: nil

  defp convert_to_decimal(value) do
    case Decimal.cast(value) do
      {:ok, dec} -> dec
      _ -> value
    end
  end

  # example: [{:time, #DateTime<2022-10-01 01:00:00+00:00 UTC UTC>}, {"foo", #Decimal<0.65>}]
  defp extract_labels(rows) when is_list(rows) do
    rows
    |> Enum.flat_map(fn
      row ->
        row
        |> Enum.map(fn {label, _value} -> label end)
        |> Enum.reject(&(&1 == :time))
    end)
    |> Enum.uniq()
  end

  attr :stats, :map, required: true

  def panel_statistics(assigns) do
    if is_nil(assigns.stats) || length(assigns.stats) == 0 do
      ~H""
    else
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
          <div><%= Utils.print_number(var.min) %></div>
          <div><%= Utils.print_number(var.max) %></div>
          <div><%= Utils.print_number(var.avg) %></div>
          <div><%= Utils.print_number(var.sum) %></div>
        <% end %>
      </div>
      """
    end
  end
end
