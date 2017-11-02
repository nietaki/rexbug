defmodule RexbugTest do
  use ExUnit.Case, async: false # we're instrumenting the system, let's not run stuff in parallel
  doctest Rexbug

  @moduletag :integration

  #===========================================================================
  # Integration tests
  #===========================================================================

  test "sample elixir module invocation" do
    validate("Foo.Bar.abc")
  end

  #---------------------------------------------------------------------------
  # Invocation validation
  #---------------------------------------------------------------------------

  describe "invocation validation" do
    test "module", do: validate(":crypto")
  end

  #===========================================================================
  # Utility functions
  #===========================================================================

  defp validate(elixir_invocation) do
    assert {x, y} = Rexbug.start(elixir_invocation, time: 20)
    assert is_integer(x)
    assert is_integer(y)
    assert stop_safely()
  end


  defp stop_safely() do
    assert Rexbug.stop_sync() in [:not_started, :stopped]
  end

end
