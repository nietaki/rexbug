defmodule Rexbug.PrintingTest do
  use ExUnit.Case
  alias Rexbug.Printing
  import ExUnit.CaptureIO

  doctest Printing

  describe "Printing.from_erl/1" do
    test "parses redbug messages" do
      msg =
        {:call, {{URI, :parse, ["https://example.com"]}, ""},
         {:c.pid(0, 150, 0), {IEx.Evaluator, :init, 4}}, {21, 49, 2, 152_927}}

      assert %Rexbug.Printing.Call{} = Printing.from_erl(msg)
    end

    test "does not raise on unrecognised messages" do
      msg = [what: "is this?"]
      assert msg == Printing.from_erl(msg)
    end

    test "handles a problematic message with code_server" do
      pid = self()

      msg =
        {:send,
         {
           {:code_call, pid, {:ensure_loaded, Inspect}},
           :code_server
         }, {pid, {IEx.Evaluator, :init, 4}}, {18, 2, 37, 897_140}}

      assert %Printing.Send{} = Printing.from_erl(msg)
    end
  end

  describe "Printing.format/_" do
    test "sample call on Elixir module" do
      msg = {
        :call,
        {
          {URI, :parse, ["https://example.com"]},
          ""
        },
        {:c.pid(0, 150, 0), {IEx.Evaluator, :init, 4}},
        {21, 49, 2, 152_927}
      }

      assert "# 21:49:02 #PID<0.150.0> IEx.Evaluator.init/4\n# URI.parse(\"https://example.com\")" ==
               Printing.format(msg)
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
        {21, 53, 7, 178_179}
      }

      assert "# 21:53:07 #PID<0.194.0> (:dead)\n# :erlang.binary_to_term/1 -> {:foo, \"bar\", 1}" ==
               Printing.format(msg)
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
        {1, 39, 54, 116_410}
      }

      assert "# 01:39:54 #PID<0.396.0> (:dead)\n# #PID<0.178.0> IEx.Evaluator.init/4 <<< {1, :foo}" ==
               Printing.format(msg)
    end

    test "sample receive message" do
      msg =
        {:recv, {1, :foo}, {:c.pid(0, 182, 0), {IEx.Evaluator, :init, 4}}, {22, 20, 4, 760_169}}

      assert "# 22:20:04 #PID<0.182.0> IEx.Evaluator.init/4\n# <<< {1, :foo}" ==
               Printing.format(msg)
    end

    test "can print with print_msec option set to true" do
      msg =
        {:recv, {1, :foo}, {:c.pid(0, 182, 0), {IEx.Evaluator, :init, 4}}, {22, 20, 4, 760_169}}

      assert "# 22:20:04 #PID" <> _rest = Printing.format(msg)
      assert "# 22:20:04 #PID" <> _rest = Printing.format(msg, print_msec: false)
      assert "# 22:20:04.760 #PID" <> _rest = Printing.format(msg, print_msec: true)
    end

    test "can print with print_msec option set to true with correct number formatting" do
      msg = {:recv, {1, :foo}, {:c.pid(0, 182, 0), {IEx.Evaluator, :init, 4}}, {1, 2, 3, 4_567}}

      assert "# 01:02:03.004 #PID" <> _rest = Printing.format(msg, print_msec: true)
    end
  end

  describe "Printing.print/1" do
    test "prints messages to stdout" do
      msg =
        {:call, {{URI, :parse, ["https://example.com"]}, ""},
         {:c.pid(0, 150, 0), {IEx.Evaluator, :init, 4}}, {21, 49, 2, 152_927}}

      io =
        capture_io(fn ->
          Rexbug.Printing.print(msg)
        end)

      assert String.contains?(io, "#PID<")
    end
  end

  describe "Printing.extract_stack/1" do
    test "works on an example info binary" do
      dump = File.read!(__DIR__ <> "/../support/dump.txt")

      expected = [
        ":erl_eval.do_apply/6",
        ":elixir.erl_eval/3",
        ":elixir.eval_forms/4",
        "IEx.Evaluator.handle_eval/6",
        "IEx.Evaluator.do_eval/4",
        "IEx.Evaluator.eval/4",
        "IEx.Evaluator.loop/3",
        "IEx.Evaluator.init/4",
        ":proc_lib.init_p_do_apply/3"
      ]

      assert expected == Printing.extract_stack(dump)
    end
  end
end
