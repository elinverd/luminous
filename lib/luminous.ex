defmodule Luminous do
  @external_resource "README.md"
  @moduledoc File.read!(@external_resource)
end
