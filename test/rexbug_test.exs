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
end
