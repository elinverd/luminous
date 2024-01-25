defmodule Luminous.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Luminous.ConnCase
      import Phoenix.LiveViewTest

      alias Luminous.Test.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint Luminous.Test.Endpoint
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
