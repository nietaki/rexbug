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

    def from_erl(a) when is_atom(a) do
      a
    end


    def represent(a) when is_atom(a) do
      inspect (a)
    end

    def represent(%__MODULE__{m: m, f: f, a: a}) do
      mrep = case Atom.to_string(m) do
        "Elixir." <> rest -> rest
        erlang_module -> ":#{erlang_module}"
      end

      arep = if is_list(a) do
        middle = a
        |> Enum.map(&inspect/1)
        |> Enum.join(", ")
        "(#{middle})"
      else
        "/#{a}"
      end

      "#{mrep}.#{f}#{arep}"
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

    def represent(%__MODULE__{hours: h, minutes: m, seconds: s}) do
      "#{format_int(h)}:#{format_int(m)}:#{format_int(s)}"
    end

    defp format_int(i, length \\ 2) do
      i
      |> Integer.to_string()
      |> String.pad_leading(length, "0")
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
        from_mfa: MFA.from_erl(from_mfa),
        time: Timestamp.from_erl(time)
      }
    end

    def represent(%__MODULE__{} = call) do
      ts = Timestamp.represent(call.time)
      pid = inspect(call.from_pid)
      from_mfa = MFA.represent(call.from_mfa)
      mfa = MFA.represent(call.mfa)

      "# #{ts} #{pid} #{from_mfa}\n# #{mfa}"
    end
  end


  #===========================================================================
  # Public Functions
  #===========================================================================

  def print(msg) do
    msg
    |> format()
    |> IO.puts()
  end

  @doc false
  def format(msg) do
    msg
    |> from_erl()
    |> represent()
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
    mod.represent(struct)
  end

  defp represent(other) do
    "OTHER: " <> inspect(other)
  end


end
