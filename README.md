[![test](https://github.com/elinverd/luminous/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/elinverd/luminous/actions/workflows/test.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/luminous)](https://hex.pm/packages/luminous)

# Luminous

Luminous is a framework for creating dashboards within [Phoenix Live
View](https://www.phoenixframework.org/).

Dashboards are defined by the client application (framework consumer)
using elixir code and consist of Panels (`Luminous.Panel`) which are
responsible for visualizing the results of multiple client-side
queries (`Luminous.Query`).

Three different types of Panels are currently offered out of the box
by Luminous:

- `Luminous.Panel.Chart` for visualizing 2-d data (including time
  series) using the [chartjs](https://www.chartjs.org/) library
  (embedded in a JS hook). Currently, only `:line` and `:bar`are
  supported.
- `Luminous.Panel.Stat` for displaying single or multiple numerical or
  other values (e.g. strings)
- `Luminous.Panel.Table` for displaying tabular data

A client application can implement its own custom panels by
implementing the `Luminous.Panel` behaviour.

Dashboards are parameterized by:

- a date range (using the [flatpickr](https://flatpickr.js.org/) library)
- user-defined variables (`Luminous.Variable`) in the form of dropdown menus

All panels are refreshed whenever at least one of these paramaters
(date range, variables) change. The parameter values are available to
client-side queries.

## Features

- Date range selection and automatic asynchronous (i.e. non-blocking
  for the UI) refresh of all dashboard panel queries
- User-facing variable dropdowns (with single- or multi- selection)
  whose selected values are available to panel queries
- Client-side zoom in charts with automatic update of the entire
  dashboard with the new date range
- Panel data downloads depending on the panel type (CSV, PNG)
- Stat panels (show single or multiple stats)
- Table panels using [tabulator](https://tabulator.info/)
- Summary statistics in charts

## Installation

The package can be installed from `hex.pm` as follows:

```elixir
def deps do
  [
    {:luminous, "~> 2.4.0"}
  ]
end
```

In order to be able to use the provided components, the library's
`javascript` and `CSS` files must be imported to your project:

In `assets/js/app.js`:

```javascript
import { ChartJSHook, TableHook, TimeRangeHook, MultiSelectVariableHook } from "luminous"

let Hooks = {
  TimeRangeHook: new TimeRangeHook(),
  ChartJSHook: new ChartJSHook(),
  TableHook: new TableHook(),
  MultiSelectVariableHook: new MultiSelectVariableHook()
}

...

let liveSocket = new LiveSocket("/live", Socket, {
  ...
  hooks: Hooks
})
...
```

Finally, in `assets/css/app.css`:
```CSS
@import "../../deps/luminous/dist/luminous.css";
```

## Usage

### Live View

The dashboard live view is defined client-side like so:

```elixir
defmodule ClientApp.DashboardLive do
  alias ClientApp.Router.Helpers, as: Routes

  use Luminous.Live,
    title: "My Title",
    path: &Routes.dashboard_path/3,
    action: :index,
    time_zone: "Europe/Paris",
    panels: [
      ...
    ],
    variables: [
      ...
    ]

  # the dashboard can be rendered by leveraging the corresponding functionality
  # from `Luminous.Components`
  def render(assigns) do
    ~H"""
    <Luminous.Components.dashboard dashboard={@dashboard} />
    """
  end
end
```

The client-side dashboard can also (optionally) implement the
`Luminous.TimeRange` behaviour in order to override the dashboard's
default time range value which is "today".

### Panels and Queries

Client-side queries must be included in a module that implements the
`Luminous.Query` behaviour:

```elixir
defmodule ClientApp.DashboardLive do

  defmodule Queries do
    @behaviour Luminous.Query

    @impl true
    def query(:my_query, _time_range, _variables) do
      [
        [{:time, ~U[2022-08-19T10:00:00Z]}, {"foo", 10}, {"bar", 100}],
        [{:time, ~U[2022-08-19T11:00:00Z]}, {"foo", 11}, {"bar", 101}]
      ]
    end
  end

  use Luminous.Live,
    ...
    panels: [
      Panel.define!(
        type: Luminous.Panel.Chart,
        id: :simple_time_series,
        title: "Simple Time Series",
        queries: [
          Luminous.Query.define(:my_query, Queries)
        ],
        description: """
        This will be rendered as a tooltip
        when hovering over the panel's title
        """
      ),
    ],
    ...
end
```

A panel may include multiple queries. When a panel is automatically
refreshed, the execution flow is as follows:

  - for each query:
    - execute the user query callback
    - execute the panel's `transform/2` callback with the query result output
  - aggregate the transformed query results
  - update the dashboard state variable with the panel's data
    (possible server-side re-rendering)
  - send a JS event to the browser (for panel hooks)

The above flow needs to be understood when implementing custom
panels. If the client application uses the panels provided by
luminous, then the panel refresh flow is handled automatically and
only `use Luminous.Live` with the appropriate options is necessary.

### Variables

Variables represent user-facing elements in the form of dropdowns in
which the user can select single (variable type: `:single`) or
multiple (variable type: `:multi`) values.

Variable selections trigger the refresh of all panels in the
dashboard. The state of all variables is available within the `query`
callback that is implemented by the client application.

Just like queries, variables must be included in a module that
implements the `Luminous.Variable` behaviour:

```elixir
defmodule ClientApp.DashboardLive do

  defmodule Variables do
    @behaviour Luminous.Variable

    @impl true
    def variable(:simple_var, _assigns), do: ["hour", "day", "week"]

    def variable(:descriptive_var, _assigns) do
      [
        %{label: "Visible Value 1", value: "val1"},
        %{label: "Visible Value 2", value: "val2"},
      ]
    end
  end

  use Luminous.Live,
    ...
    variables: [
      Luminous.Variable.define!(id: :simple_var, label: "Select one value", module: Variables),
      Luminous.Variable.define!(id: :descriptive_var, label: "Select one value", module: Variables),
    ],
    ...
end
```

The variable callback will receive the live view socket assigns as the
second argument, however it is important to note that the `variable/2`
callback is executed once when the dashboard is loaded for populating
the dropdown values.

### Demo

Luminous provides a demo dashboard that showcases some of Luminous'
capabilities. The demo dashboard can be inspected live using the
project's development server (run `mix run` in the project and then
visit [this page](http://localhost:5000)).
