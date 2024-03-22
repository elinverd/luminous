defmodule Luminous.VariableTest do
  use ExUnit.Case

  alias Luminous.Variable

  defmodule Variables do
    @behaviour Variable
    def variable(:foo, _), do: ["a", "b"]
  end

  describe "populate/2" do
    test "the default value of a single variable is the first list element" do
      assert [id: :foo, label: "Foo", module: Variables, type: :single]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.get_current()
             |> Variable.extract_value() == "a"
    end

    test "the default value of a multi variable is the selection of all list elements by default" do
      assert [id: :foo, label: "Foo", module: Variables, type: :multi]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.get_current()
             |> Variable.extract_value() == ["a", "b"]
    end

    test "the default value of a multi variable is an empty list when specified as such" do
      assert [id: :foo, label: "Foo", module: Variables, type: :multi, multi_default: :none]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.get_current()
             |> Variable.extract_value()
             |> Enum.empty?()
    end
  end

  describe "update_current" do
    test "should update the current value of a single variable" do
      assert [id: :foo, label: "Foo", module: Variables, type: :single]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current("b", %{})
             |> Variable.get_current()
             |> Variable.extract_value() == "b"
    end

    test "should not update the current value of a single variable if the new value is not legit" do
      assert [id: :foo, label: "Foo", module: Variables, type: :single]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current("invalid value", %{})
             |> Variable.get_current()
             |> Variable.extract_value() == "a"
    end

    test "should not update the current value of a multi variable if the new value is not legit" do
      assert [id: :foo, label: "Foo", module: Variables, type: :multi]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current(["invalid value 1", "invalid value 2"], %{})
             |> Variable.get_current()
             |> Variable.extract_value() == ["a", "b"]
    end

    test "should update the current value of a hidden single variable regardless of the new value" do
      assert [id: :foo, label: "Foo", module: Variables, type: :single, hidden: true]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current("arbitrary value 1", %{})
             |> Variable.get_current()
             |> Variable.extract_value() == "arbitrary value 1"
    end

    test "should update the current value of a hidden multi variable regardless of the new value" do
      assert [id: :foo, label: "Foo", module: Variables, type: :multi, hidden: true]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current(["arbitrary value 1", "arbitrary value 2"], %{})
             |> Variable.get_current()
             |> Variable.extract_value() == ["arbitrary value 1", "arbitrary value 2"]
    end

    test "should handle the special 'none' value in the case of a multi variable" do
      assert [id: :foo, label: "Foo", module: Variables, type: :multi]
             |> Variable.define!()
             |> Variable.populate(%{})
             |> Variable.update_current("none", %{})
             |> Variable.get_current()
             |> Variable.extract_value() == []
    end

    test "should return the default value when the new value is nil" do
      var =
        [id: :foo, label: "Foo", module: Variables, type: :single]
        |> Variable.define!()
        |> Variable.populate(%{})
        |> Variable.update_current("b", %{})

      assert var
             |> Variable.update_current(nil, %{})
             |> Variable.get_current()
             |> Variable.extract_value() == "a"
    end
  end
end
