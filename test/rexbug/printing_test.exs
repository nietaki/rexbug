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

    test "sample send message" do
      msg = {
        :send,
        {
          {1, :foo},
          {
            :c.pid(0, 178, 0),
            {IEx.Evaluator, :init, 4}
          }
        },
        {
          :c.pid(0, 396, 0),
          :dead
        },
        {1, 39, 54, 116410}
      }
      assert "# 01:39:54 #PID<0.396.0> DEAD\n# #PID<0.178.0> IEx.Evaluator.init/4 <<< {1, :foo}" == Printing.format(msg)
    end

    test "sample receive message" do
      msg = {:recv, {1, :foo}, {:c.pid(0, 182, 0), {IEx.Evaluator, :init, 4}}, {22, 20, 4, 760169}}

      assert "# 22:20:04 #PID<0.182.0> IEx.Evaluator.init/4\n# <<< {1, :foo}" == Printing.format(msg)
    end

  end

end
