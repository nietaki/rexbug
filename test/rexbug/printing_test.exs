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
  end

end
