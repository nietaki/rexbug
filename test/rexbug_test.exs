defmodule RexbugTest do
  use ExUnit.Case, async: false # we're instrumenting the system, let's not run stuff in parallel
  doctest Rexbug

  @moduletag :integration

  #===========================================================================
  # Integration tests
  #===========================================================================

  test "sample elixir module invocation" do
    assert {:timeout, 0} = Rexbug.start("Foo.Bar.abc", :return, blocking: true, time: 10)
  end


end
