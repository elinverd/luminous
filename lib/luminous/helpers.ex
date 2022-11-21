defmodule Luminous.Helpers do
  alias Luminous.Variable

  @doc """
  Interpolate all occurences of variable IDs in the format `$variable.id` in the string
  with the variable's descriptive value label. For example, the string: "Energy for asset $asset_var"
  will be replaced by the label of the variable with id `:asset_var` in variables.
  """
  @spec interpolate(binary(), [Variable.t()]) :: binary()
  def interpolate(string, variables) do
    variables
    |> Enum.reduce(string, fn var, title ->
      val =
        var
        |> Variable.get_current()
        |> Variable.extract_label()

      String.replace(title, "$#{var.id}", "#{val}")
    end)
  end
end
