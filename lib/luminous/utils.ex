defmodule Luminous.Utils do
  @moduledoc """
  Various utility functions.
  """

  alias Phoenix.LiveView.JS
  alias Luminous.Variable

  def dom_id(%{id: id}), do: "panel-#{id}"

  def print_number(%Decimal{} = n), do: Decimal.to_string(n)
  def print_number(nil), do: "-"
  def print_number(n), do: n
end
