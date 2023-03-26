defmodule RexbugIntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  setup do
    Code.ensure_loaded!(Foo.Bar)
    :ok
  end

  test "base redbug invocation" do
    assert {i, p} = :redbug.start('\'Elixir.Foo.Bar\'')
    assert is_integer(i), inspect({i, p})
    assert is_integer(p), inspect({i, p})
    Rexbug.stop_sync()
  end

  test "base redbug with non-existent module" do
    assert {i, p} = :redbug.start('\'Elixir.Foo.Xxxxxxx\'')
    refute is_integer(i), inspect({i, p})
    refute is_integer(p), inspect({i, p})
    Rexbug.stop_sync()
  end
end
