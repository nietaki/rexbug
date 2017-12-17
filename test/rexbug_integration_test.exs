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

    # all argument types
    test "integers", do: validate("Foo.Bar.xyz(1, 9_001, 0xFF)")
    test "strings", do: validate("Foo.Bar.xyz(\"foo\", \"bar baz\", \"\")")
    test "binaries", do: validate("Foo.Bar.xyz(<<>>, <<104, 97, 120>>, <<\"wat\">>)")
    test "charlists", do: validate("Foo.Bar.xyz('', 'foo', 'bar')")
    test "lists", do: validate("Foo.Bar.xyz([], [_], [1, 2, 3])")
    test "tuples", do: validate("Foo.Bar.xyz({}, {_, _}, {1, 2, 3})")
    test "underscores", do: validate("Foo.Bar.xyz(_, _foo, _bar)")
    test "variables", do: validate("Foo.Bar.xyz(foo, bar, baz)")
    test "atoms", do: validate("Foo.Bar.xyz(:foo, :\"bar baz\", :{})")

    test "complicated case", do: validate("Foo.Bar.xyz(_, [foo], c)")
    test "complicated case with tuples", do: validate("Foo.Bar.xyz({1, 1}, [_], {_, _, _})")
    test "complicated case with tuples 2", do: validate("Foo.Bar.xyz({a, b}, [_], {_, _, _})")

    test "example from help 1", do: validate(":ets.lookup(t, :hostname) when is_integer(t)")
    test "example from help 2", do: validate("Map.new/2")
    test "example from help 3", do: validate("Map.pop(_, :some_key, default) when default != nil")
    test "example from help 4", do: validate("Agent")
    test "example from help 5", do: validate("Map.new/any")
    test "example from help 6", do: validate("Map.new/x")

    test "send", do: validate(:send)
    test "receive", do: validate(:receive)

    test "multiple trace patterns", do: validate([":ets", ":dets"])
  end

  #===========================================================================
  # Utility functions
  #===========================================================================

  defp validate(elixir_invocation, options \\ []) do
    options = [time: 20] ++ options
    capture_io(fn ->
      assert {x, y} = res = Rexbug.start(elixir_invocation, options)
      case {is_integer(x), is_integer(y)} do
        {true, true} -> :all_good
        _ -> flunk(inspect(res) <> " returned by Rexbug.start()" )
      end
      assert stop_safely()
    end)
  end


  defp stop_safely() do
    assert Rexbug.stop_sync() in [:not_started, :stopped]
  end

end
