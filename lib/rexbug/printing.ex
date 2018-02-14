defmodule Rexbug.Printing do
  defmodule MFA do
    defstruct [
      :m,
      :f,
      :a, # either args or arity
    ]

    def from_erl({m, f, a}) do
      %__MODULE__{m: m, f: f, a: a}
    end
  end

  defmodule Timestamp do
    defstruct [
      :hours,
      :minutes,
      :seconds,
      :us,
    ]

    def from_erl({h, m, s, us}) do
      %__MODULE__{hours: h, minutes: m, seconds: s, us: us}
    end
  end

  # :call, :retn, :send, :recv

  defmodule Call do
    defstruct [
      :mfa,
      :info,
      :from_pid,
      :from_mfa,
      :time
    ]

    # {
    #   :call,
    #   {
    #     {URI, :parse, ["https://example.com"]},
    #     ""
    #   },
    #   {PID<0.150.0>, {IEx.Evaluator, :init, 4}},
    #     {21, 49, 20, 152927}
    # }
    def from_erl({:call, {mfa, info}, {from_pid, from_mfa}, time}) do
      %__MODULE__{
        mfa: MFA.from_erl(mfa),
        info: info,
        from_pid: from_pid,
        from_mfa: from_mfa,
        time: Timestamp.from_erl(time)
      }
    end

    def represent(%__MODULE__{} = call) do
      "FOO: " <> inspect(call)
    end
  end


  #===========================================================================
  # Public Functions
  #===========================================================================

  def print(msg) do
    msg
    |> from_erl()
    |> represent()
    |> IO.puts()
  end

  #===========================================================================
  # Private Functions
  #===========================================================================

  defp from_erl({:call, _, _, _} = call) do
    Call.from_erl(call)
  end

  defp from_erl(other) do
    other
  end


  defp represent(%mod{} = struct) when mod in [Call] do
    "SPECIAL: " <> mod.represent(struct)
  end

  defp represent(other) do
    "OTHER: " <> inspect(other)
  end


end
