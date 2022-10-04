[![test](https://github.com/elinverd/luminous/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/elinverd/luminous/actions/workflows/test.yml)

# Luminous

Luminous is a framework for creating dashboards within [Phoenix Live
Views](https://www.phoenixframework.org/). It is somewhat inspired by
grafana both conceptually and functionally in that:

- it focuses on time series data
- it is organized around panels
- it is parameterized by a time range
- it can be parameterized by user-defined variables

Dashboards are defined at compile time using elixir code (see
`Luminous.Dashboard.define/5`). At runtime, Luminous uses the
following javascript libraries (as [live view
hooks](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook))
for supporting client-side visualizations and interactions with the
server-side process:

- [chartjs](https://www.chartjs.org/) for plots
- [flatpickr](https://flatpickr.js.org/) for time range selection

Luminous is currently used in production systems and has demonstrated
solid performance and stability characteristics.

## Installation

The package can be installed by adding `luminous` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:luminous, "~> 0.5.0"}
  ]
end
```

For the moment, Luminous assumes that it will be embedded in a typical
Phoenix Live View application with
[tailwind](https://tailwindcss.com/),
[alpinejs](https://alpinejs.dev/) and
[daisyui](https://daisyui.com/).

While this assumption may change in the future, the fact is that the
first two libraries (tailwind and alpine) are pretty standard in
phoenix live view apps. Daisyui can be added in `assets/package.json`:

```json
{
    ...
    "dependencies": {
        ...
        "daisyui": "^2.13.4",
        ...
    }
}
```

and installed using `cd assets && npm install`.

Then in `assets/tailwind.config.js`:

```json
...
module.exports = {
    ...
    content: [..., "../lib/luminous/components.ex"],
    ...
    plugins: [
        ...
        require('daisyui'),
        ...
    ]
}
```

Finally in `assets/js/app.js`:

```javascript
import 'alpinejs'
import { ChartJSHook, TimeRangeHook } from "../../deps/luminous/dist/luminous"

let Hooks = {
  TimeRangeHook: new TimeRangeHook(),
  ChartJSHook: new ChartJSHook()
}

...

let liveSocket = new LiveSocket("/live", Socket, {
    dom: {
        onBeforeElUpdated(from, to) {
            if (from.__x) {
                window.Alpine.clone(from.__x, to)
            }
        }
    },
    params: { _csrf_token: csrfToken },
    hooks: Hooks
})
...
```

Based on the above setup, your app's asset pipeline will build and
include the necessary luminous js and css resources.

## Usage

A [demo dashboard](dev/demo_dashboard_live.ex) has been provided that
showcases some of Luminous' capabilities.

The demo can be inspected live using the project's dev server (run
`mix dev` in the project and then visit [this
page](http://localhost:5000/demo)).

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
