defmodule Rexbug.DtopTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Rexbug.Dtop

  doctest Dtop

  @moduletag :integration
  @moduletag :coveralls_safe
  describe "dtop" do
    test "can be run twice to change the settings" do
      capture_io(fn ->
        refute Dtop.running?()
        assert {:ok, :started} = Dtop.dtop()
        assert Dtop.running?()
        assert {:ok, :reconfigured} = Dtop.dtop(max_procs: 20, sort: :mem)
        assert Dtop.running?()
        assert {:ok, :stopped} = Dtop.dtop()
        refute Dtop.running?()
      end)
    end

    test "validates sort settings values" do
      output =
        capture_io(fn ->
          refute Dtop.running?()
          assert {:error, :invalid_sort_type} = Dtop.dtop(sort: :foo)
          refute Dtop.running?()
        end)

      assert String.contains?(output, "Supported")
    end

    test "validates max_proc settings values" do
      output =
        capture_io(fn ->
          refute Dtop.running?()
          assert {:error, :invalid_max_procs} = Dtop.dtop(max_procs: -3)
          assert {:error, :invalid_max_procs} = Dtop.dtop(max_procs: "banana")
          refute Dtop.running?()
        end)

      assert String.contains?(output, "Supported")
    end

    test "reports invalid config options" do
      output =
        capture_io(fn ->
          refute Dtop.running?()
          assert {:error, {:unrecognised_option, :power_level}} = Dtop.dtop(power_level: 9001)
          refute Dtop.running?()
        end)

      assert String.contains?(output, "Supported")
    end
  end

  describe "explicit functions" do
    test "E2E case" do
      capture_io(fn ->
        refute Dtop.running?()
        assert {:error, :dtop_not_running} = Dtop.stop()
        refute Dtop.running?()
        assert {:error, :dtop_not_running} = Dtop.configure(sort: :cpu)
        refute Dtop.running?()
        assert {:ok, :started} = Dtop.start()
        assert Dtop.running?()
        assert {:error, :dtop_already_running} = Dtop.start()
        assert Dtop.running?()
        assert {:ok, :reconfigured} = Dtop.configure(max_procs: 20, sort: :mem)
        assert Dtop.running?()
        assert {:ok, :stopped} = Dtop.stop()
        refute Dtop.running?()
      end)
    end
  end
end
