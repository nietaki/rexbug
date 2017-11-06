defmodule RexbugIntegrationTest do

  use ExUnit.Case, async: false # we're instrumenting the system, let's not run stuff in parallel

  import ExUnit.CaptureIO

  @moduletag :integration

  #===========================================================================
  # Integration tests
  #===========================================================================

  #---------------------------------------------------------------------------
  # Invocation validation
  #---------------------------------------------------------------------------

  describe "invocation validation" do
    test "module", do: validate(":crypto")
    test "elixir module", do: validate("Foo.Bar")
    test "zero arity function in an elixir module", do: validate("Foo.Bar.abc")
    test "zero arity function in an elixir module, with parens", do: validate("Foo.Bar.abc()")
    test "explicit zero arity function", do: validate("Foo.Bar.abc/0")
    test "explicit 3 arity function", do: validate("Foo.Bar.xyz/3")
    test "zero arity function in an elixir module, with actions", do: validate("Foo.Bar.abc :: return")
    test "multiple actions", do: validate("Foo.Bar.abc :: return;stack")
    test "no actions", do: validate("Foo.Bar.abc :: ")
    test "no actions and no space after ::", do: validate("Foo.Bar.abc ::")
    test "complicated case", do: validate("Foo.Bar.xyz(#\{\}, [foo], c)")
  end

  #===========================================================================
  # Utility functions
  #===========================================================================

  defp validate(elixir_invocation, options \\ []) do
    options = [time: 20] ++ options
    capture_io(fn ->
      assert {x, y} = Rexbug.start(elixir_invocation, options)
      assert is_integer(x)
      assert is_integer(y)
      assert stop_safely()
    end)
  end


  defp stop_safely() do
    assert Rexbug.stop_sync() in [:not_started, :stopped]
  end

end
