defmodule RexbugTest do
  use ExUnit.Case, async: true

  doctest Rexbug

  test "if trace pattern validation fails, the error gets returned" do
    assert {:error, _} = Rexbug.start("¯\_(ツ)_/¯")
  end

  test "if the options are harshly invalid, the error gets returned" do
    assert {:error, :invalid_options} = Rexbug.start("Foo", [{:foo, :bar, :baz}])
  end

end
