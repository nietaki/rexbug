defmodule RexbugTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  doctest Rexbug

  test "if trace pattern validation fails, the error gets returned" do
    assert {:error, _} = Rexbug.start("¯\_(ツ)_/¯")
    assert {:error, _} = Rexbug.start("¯\_(ツ)_/¯", [])
    assert {:error, _} = Rexbug.start(10_000, 10, "¯\_(ツ)_/¯")
    assert {:error, _} = Rexbug.start(10_000, 10, self(), "¯\_(ツ)_/¯")
    assert {:error, _} = Rexbug.start(10_000, 10, self(), Node.self(), "¯\_(ツ)_/¯")
  end

  test "if the options are harshly invalid, the error gets returned" do
    assert {:error, :invalid_options} = Rexbug.start("Foo", [{:foo, :bar, :baz}])
  end

  test "Rexbug.help() uses Elixir syntax" do
    output =
      capture_io(fn ->
        assert :ok = Rexbug.help()
      end)

    assert String.contains?(output, "<mfa> when <guards> :: <actions>")
    assert String.contains?(output, "Mod.fun/_")
  end

  test "Rexbug.stop() when Rexbug isn't started" do
    assert :not_started = Rexbug.stop()
  end

  test "Rexbug.stop_sync() when Rexbug isn't started" do
    assert :not_started = Rexbug.stop_sync()
  end

  test "Rexbug.stop_sync() will report timeout if not given enough time" do
    capture_io(fn ->
      {_, _} = Rexbug.start(":dets", print_re: ~r/lkdfjlksjfdlkjsdflkjsdflkjf/)
      :ok = wait_for_redbug_up(50)
      assert {:error, :could_not_stop_redbug} = Rexbug.stop_sync(0)

      # cleanup
      Rexbug.stop_sync()
    end)
  end

  describe "Rexbug.dtop()" do
    test "when called with invalid args prints the help message" do
      output =
        capture_io(fn ->
          Rexbug.dtop(:foo)
        end)

      assert String.contains?(output, "Supported")

      o2 =
        capture_io(fn ->
          Rexbug.dtop([1, 2, 3])
        end)

      assert output == o2
    end

    @tag :integration
    @tag :coveralls_safe
    test "prints node info" do
      output =
        capture_io(fn ->
          Rexbug.dtop()
          Process.sleep(3000)
          pid = Process.whereis(:redbug_dtop)
          ref = Process.monitor(pid)
          Rexbug.dtop(%{})

          receive do
            {:DOWN, ^ref, _, _, _} ->
              :stopped
          after
            100 -> flunk("could not stop dtop")
          end
        end)

      assert String.contains?(output, "cpu%:")
    end
  end

  @redbug_up_step_ms 1
  defp wait_for_redbug_up(max_ms) when max_ms <= 0 do
    :error
  end

  defp wait_for_redbug_up(max_ms) do
    case Process.whereis(:redbug) do
      nil ->
        Process.sleep(@redbug_up_step_ms)
        wait_for_redbug_up(max_ms - @redbug_up_step_ms)

      _pid ->
        :ok
    end
  end
end
