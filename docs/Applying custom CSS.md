`luminous` provides CSS classes that can be overriden, so that the components match the look and feel of the consumer application. Those classes belong to three `luminous` components:
- Variables
- Time range selector
- Panel dropdown

### Variables

#### `lmn-variable-button`
Define the size, shape, background color, on hover behavior, etc. of the variable buttons.

#### `lmn-variable-button-label`
Define the font, text size, weight, alignment of the variable button's label.

#### `lmn-variable-button-label-prefix`
Define the font, text size, weight, alignment of the variable button's label prefix.

#### `lmn-variable-button-icon`
Define the size and alignment of the variable button's chevron icon.

#### `lmn-variable-dropdown`
Define the size, background color, rouding, shadows, etc. of the variable dropdown menu.

#### `lmn-variable-dropdown-item-container`
Define the text alignment, rounding, on hover behaviour, etc. of each item in the variable dropdown menu.

#### `lmn-variable-dropdown-item-content`
Define the size, padding, etc. of the content of each item in the variable dropdown menu.

### Time range picker

#### `lmn-time-range-compound`
Define the structure of the time range component. This includes the time range picker button, the pressets button and the time zone component.

#### `lmn-time-range-selector`
Define the structure, the size and the shape of the time range selector component. This includes the button that opens the custom time range selector and the button that opens the preset menu dropdown.

#### `lmn-custom-time-range-input`
Define the size, background color, text size, on hover behavior, etc. of the button that opens the custom date range picker dropdown.

#### `lmn-time-range-presets-button`
Define the size, background color, on hover behavior, etc. of the button that opens the time range presets dropdown.

#### `lmn-time-range-presets-button-icon`
Define the size and spacing of the icon in the button that opens the time range presets dropdown.

#### `lmn-time-range-presets-dropdown`
Define the size, background color, rouding, shadows, etc. of the time range presets dropdown menu.

#### `lmn-time-range-presets-dropdown-item-container`
Define the text alignment, rounding, on hover behaviour, etc. of each item in the time range presets dropdown menu.

#### `lmn-time-range-presets-dropdown-item-content`
Define the size, padding, etc. of the content of each item in the time range presets dropdown menu.

#### `lmn-time-zone`
Define the background color, rounding, text size, etc. of the time zone label

### Panel dropdown

#### `lmn-panel-actions-dropdown`
Define the size, background color, rouding, shadows, etc. of the panel actions dropdown menu.

#### `lmn-panel-actions-dropdown-item-container`
Define the text alignment, rounding, on hover behaviour, etc. of each item in the panel actions dropdown menu.

#### `lmn-panel-actions-dropdown-item-content`
Define the size, padding, etc. of the content of each item in the panel actions dropdown menu.

### Dropdown transition

#### `lmn-dropdown-transition-enter`
Define the animation of all dropdowns when they open up.

#### `lmn-dropdown-transition-start`
Define the initial state of the animation of all dropdowns when they open up.

#### `lmn-dropdown-transition-end`
Define the final state of the animation of all dropdowns when they open up.

### Calendar dropdown
For the calendar dropdown, by default we use the [`airbnb`](https://flatpickr.js.org/themes/) theme provided by `flatpickr`.
To change this theme, you have to import the desired theme **after** importing `luminous` to your `app.css` file like so:

```CSS
@import 'luminous/dist/luminous';
@import '../node_modules/flatpickr/dist/themes/material_blue.css';
```

The path that the `flatpickr` theme resides, depends on your project's directory structure.