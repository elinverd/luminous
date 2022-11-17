[![test](https://github.com/elinverd/luminous/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/elinverd/luminous/actions/workflows/test.yml)

# Luminous

Luminous is a framework for creating dashboards within [Phoenix Live
View](https://www.phoenixframework.org/). It is somewhat inspired by
grafana both conceptually and functionally in that:

- it focuses on time series data (albeit not exclusively)
- it is organized around panels
- it is parameterized by a time range
- it can be parameterized by user-defined variables

Dashboards are defined at compile time using elixir code (see
`Luminous.Dashboard.define/5`). At runtime, Luminous uses the
following javascript libraries (as [live view
hooks](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook))
for supporting client-side visualizations and interactions with the
live view process:

- [chartjs](https://www.chartjs.org/) for plots
- [flatpickr](https://flatpickr.js.org/) for time range selection

Luminous is currently used in production systems and has demonstrated
solid performance and stability characteristics. At the same time, it
is currently under development and some things may change.

## Installation

The package is not yet published to `hex.pm` but can be installed
directly from this repo by adding `luminous` to your list of
dependencies in `mix.exs` like so:

```elixir
def deps do
  [
    {:luminous, git: "https://github.com/elinverd/luminous.git", branch: "main"}
  ]
end
```

`luminous` assumes that it will be embedded in a standard Phoenix LiveView application with [tailwindcss](https://tailwindcss.com/).

In order to be able to use the provided components, the library's `javascript` and
`CSS` files must be imported to your project:

In `assets/package.json`:
```javascript
...
"dependencies": {
  "luminous": "file:../deps/luminous"
}
```

In `assets/js/app.js`:

```javascript
import { ChartJSHook, TimeRangeHook } from "luminous"

let Hooks = {
  TimeRangeHook: new TimeRangeHook(),
  ChartJSHook: new ChartJSHook()
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
@import "luminous/dist/luminous";
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

In general, a custom dashboard needs to:

- implement the `Luminous.Variable` behaviour for the
  dashboard-specific variables
- implement the `Luminous.Query` behaviour for loading the necessary
  data that will be visualized in the client
- implement the `Luminous.TimeRangeSelector` behaviour for determining
  the default time range for the dashboard
- `use` the `Luminous.Live` module for leveraging the live dashboard
  functionality and capabilities
- render the dashboard in the view template (only
  `Luminous.Components.dashboard` is necessary but the layout can be
  customized by using directly the various components in
  `Luminous.Components`)

## Features

- Time range selection and refresh of all dashboard panel queries
- Asynchronous queries and page updates
- User-facing variable dropdowns that are available to panel queries
- Client-side zoom in charts
- Multiple supported chart types (currently `:line` and `:bar`)
- Download panel data (CSV, PNG)
- Stat panels (show single or multiple stats)
- Summary statistics in panels

## Development

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found
at <https://hexdocs.pm/luminous>.
