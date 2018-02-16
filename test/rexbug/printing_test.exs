defmodule Rexbug.PrintingTest do
  use ExUnit.Case
  alias Rexbug.Printing
  doctest Printing

  describe "Printing.format/1" do
    test "sample call on Elixir module" do
      msg = {
        :call,
        {
          {URI, :parse, ["https://example.com"]},
          ""
        },
        {:c.pid(0, 150, 0), {IEx.Evaluator, :init, 4}},
          {21, 49, 2, 152927}
      }
      assert "# 21:49:02 #PID<0.150.0> IEx.Evaluator.init/4\n# URI.parse(\"https://example.com\")" == Printing.format(msg)
    end

    test "sample return message" do
      msg = {
        :retn,
        {
          {:erlang, :binary_to_term, 1},
          {:foo, "bar", 1}
        },
        {
          :c.pid(0, 194, 0),
          :dead
        },
        {21, 53, 7, 178179}
      }

      assert "# 21:53:07 #PID<0.194.0> DEAD\n# :erlang.binary_to_term/1 -> {:foo, \"bar\", 1}" == Printing.format(msg)
    end
  end

end
