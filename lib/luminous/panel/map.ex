defmodule Luminous.Panel.Map do
  alias Luminous.Query
  @behaviour Luminous.Panel
  @impl true

  def transform(%Query.Result{rows: rows, attrs: _}), do: rows
end
