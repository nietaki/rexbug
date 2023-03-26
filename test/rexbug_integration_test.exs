defmodule RexbugIntegrationTest do
  # we're instrumenting the system, let's not run stuff in parallel
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @moduletag :integration

  # ===========================================================================
  # Integration tests
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Invocation validation
  # ---------------------------------------------------------------------------

  describe "invocation validation" do
    test "module", do: validate(":crypto")
    test "elixir module", do: validate("Foo.Bar")
    test "zero arity function in an elixir module", do: validate("Foo.Bar.abc")
    test "zero arity function in an elixir module, with parens", do: validate("Foo.Bar.abc()")
    test "explicit zero arity function", do: validate("Foo.Bar.abc/0")
    test "explicit 3 arity function", do: validate("Foo.Bar.xyz/3")

    test "zero arity function in an elixir module, with actions",
      do: validate("Foo.Bar.abc :: return")

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

  describe "actual integration tests" do
    test "simple case" do
      trigger = fn -> Foo.Bar.abc() end
      assert_triggers(trigger, "Foo.Bar.abc()")
    end

    test "simple case with erlang" do
      assert_triggers(&:ets.all/0, ":ets.all()")
    end

    test "simple case with guards" do
      trigger = fn -> Foo.Bar.xyz(1, "b", [3, :four]) end
      assert_triggers(trigger, "Foo.Bar.xyz/_")
      assert_triggers(trigger, "Foo.Bar.xyz(1, _, _)")
      refute_triggers(trigger, "Foo.Bar.xyz(13, _, _)")
      assert_triggers(trigger, "Foo.Bar.xyz(x, _, _) when x == 1")
      assert_triggers(trigger, "Foo.Bar.xyz(x, _, _) when x <= 1")
      assert_triggers(trigger, "Foo.Bar.xyz(x, _, _) when is_integer(x) and x > 0")
    end

    test "list manipulation in guards" do
      trigger = fn -> Foo.Bar.xyz(1, "b", [3, :four]) end
      assert_triggers(trigger, "Foo.Bar.xyz(_, _, [_, _])")
      refute_triggers(trigger, "Foo.Bar.xyz(_, _, [])")
      assert_triggers(trigger, "Foo.Bar.xyz(_, _, ls) when is_list(ls)")
      assert_triggers(trigger, "Foo.Bar.xyz(_, _, ls) when is_list(ls) and hd(ls) == 3")

      # here b isn't even a list, but everything works ok
      refute_triggers(trigger, "Foo.Bar.xyz(_, b, _) when hd(b) == :wat")
      refute_triggers(trigger, "Foo.Bar.xyz(_, _, [_, :wat])")
      assert_triggers(trigger, "Foo.Bar.xyz(_, _, [_, :four])")
      assert_triggers(trigger, "Foo.Bar.xyz(_, _, ls) when tl(ls) == [:four]")
    end
  end

  # ===========================================================================
  # Utility functions
  # ===========================================================================

  defp validate(elixir_invocation, options \\ []) do
    options = [time: 200, procs: [self()]] ++ options

    capture_io(fn ->
      assert {1, y} = res = Rexbug.start(elixir_invocation, options)

      case is_integer(y) do
        true ->
          :all_good

        _ ->
          flunk(inspect(res) <> " returned by Rexbug.start()")
      end

      assert stop_safely()
    end)
  end

  defp refute_triggers(trigger_fun, spec) do
    assert_triggers(trigger_fun, spec, false)
  end

  defp assert_triggers(trigger_fun, spec, should_trigger \\ true)
       when is_function(trigger_fun, 0) and is_binary(spec) do
    capture_io(fn ->
      me = self()
      tell_me = fn msg -> tell_me_non_meta(me, msg) end
      options = [time: 100, procs: [me], print_fun: tell_me]
      assert {1, _} = Rexbug.start(spec, options)
      trigger_fun.()

      triggered =
        receive do
          {:triggered, _msg} ->
            Rexbug.stop_sync()
            true
        after
          50 ->
            Rexbug.stop_sync()
            false
        end

      case should_trigger do
        true -> assert(triggered, "the function should trigger `#{spec}`, but it didn't")
        false -> assert(!triggered, "the function shouldn't trigger `#{spec}`, but it did")
      end
    end)
  end

  defp tell_me_non_meta(me, msg) do
    case msg do
      {:meta, _, _, _} -> :ok
      _ -> send(me, {:triggered, msg})
    end
  end

  defp stop_safely() do
    assert Rexbug.stop_sync(1000) in [:not_started, :stopped]
  end
end
