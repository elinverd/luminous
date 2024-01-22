[![test](https://github.com/elinverd/luminous/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/elinverd/luminous/actions/workflows/test.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/luminous)](https://hex.pm/packages/luminous)

# Luminous

Luminous is a framework for creating dashboards within [Phoenix Live
View](https://www.phoenixframework.org/).

Dashboards are defined using elixir code and consist of Panels which
are responsible for visualizing the results of client-side
Queries. Three different types of Panels are currently supported:

- `Panel.Chart` for visualizing 2-d data (including time series) using
  the [chartjs](https://www.chartjs.org/) library (embedded in a JS hook)
- `Panel.Stat` for displaying single or multiple numerical or other values
- `Panel.Table` for displaying tabular data using the
  [tabulator](https://tabulator.info/) JS library (embedded in a JS
  hook)

Dashboards can be parameterized by a time range (using the
[flatpickr](https://flatpickr.js.org/)) and by user-defined variables
in the form of dropdown menus.

## Features

- Time range selection and automatic refresh of all dashboard panel queries
- Asynchronous queries and page updates
- User-facing variable dropdowns whose selected values are available to panel queries
- Client-side zoom in charts
- Multiple supported chart types (currently `:line` and `:bar`)
- Download panel data (CSV, PNG)
- Stat panels (show single or multiple stats)
- Table panels
- Summary statistics in charts

## Installation

The package can be installed from `hex.pm` as follows:

```elixir
def deps do
  [
    {:luminous, "~> 2.0.0"}
  ]
end
```

In order to be able to use the provided components, the library's
`javascript` and `CSS` files must be imported to your project:

In `assets/js/app.js`:

```javascript
import { ChartJSHook, TableHook, TimeRangeHook } from "luminous"

let Hooks = {
  TimeRangeHook: new TimeRangeHook(),
  ChartJSHook: new ChartJSHook(),
  TableHook: new TableHook()
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

A [demo dashboard](dev/demo_dashboard_live.ex) has been provided that
showcases some of Luminous' capabilities.

The demo can be inspected live using the project's dev server (run
`mix dev` in the project and then visit [this
page](http://localhost:5000/demo)).

Luminous is a framework in the sense that the luminous client is
responsible for specifying queries, variables etc. and `Luminous.Live`
will call the client's code by setting up all the required plumbing.

In general, a custom client-side dashboard needs to:

- implement the `Luminous.Variable` behaviour for the
  dashboard-specific variables
- implement the `Luminous.Query` behaviour for loading the necessary
  data that will be visualized in the client
- implement the `Luminous.Dashboard` behaviour for determining
  the default time range for the dashboard and optionally injecting
  parameters to `Luminous.Variable.variable/2` callbacks
  (see `Luminous.Dashboard.parameters/1`)
- `use` the `Luminous.Live` module to configure the `Luminous.Dashboard`
- render the dashboard in the view template (only
  `Luminous.Components.dashboard` is necessary but the layout can be
  customized by using directly the various components in
  `Luminous.Components`)
