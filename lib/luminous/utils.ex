defmodule Luminous.Utils do
  alias Phoenix.LiveView.JS
  alias Luminous.Variable

  def dom_id(%{id: id}), do: "panel-#{id}"

  def show_dropdown(dropdown_id) do
    JS.show(
      to: "##{dropdown_id}",
      transition:
        {"lmn-dropdown-transition-enter", "lmn-dropdown-transition-start",
         "lmn-dropdown-transition-end"}
    )
  end

  def hide_dropdown(dropdown_id) do
    JS.hide(to: "##{dropdown_id}")
  end

  def print_number(%Decimal{} = n), do: Decimal.to_string(n)
  def print_number(nil), do: "-"
  def print_number(n), do: n

  # Interpolate all occurences of variable IDs in the format `$variable.id` in the string
  # with the variable's descriptive value label. For example, the string: "Energy for asset $asset_var"
  # will be replaced by the label of the variable with id `:asset_var` in variables.
  @spec interpolate(binary(), [Variable.t()]) :: binary()
  def interpolate(nil, _), do: ""

  def interpolate(string, variables) do
    Enum.reduce(variables, string, fn var, title ->
      String.replace(title, "$#{var.id}", "#{Variable.get_current_label(var)}")
    end)
  end
end
