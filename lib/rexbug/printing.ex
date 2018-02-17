defmodule Rexbug.Printing do
  import Rexbug.Printing.Utils

  #===========================================================================
  # Helper Structs
  #===========================================================================

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
      a
      |> Atom.to_string()
      |> String.upcase()
    end

    def represent(%__MODULE__{m: m, f: f, a: a}) do
      mrep = case Atom.to_string(m) do
        "Elixir." <> rest -> rest
        erlang_module -> ":#{erlang_module}"
      end

      arep = if is_list(a) do
        middle = a
        |> Enum.map(&printing_inspect/1)
        |> Enum.join(", ")
        "(#{middle})"
      else
        "/#{a}"
      end

      "#{mrep}.#{f}#{arep}"
    end
  end

  defmodule Timestamp do
    defstruct ~w(hours minutes seconds us)a

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

  #---------------------------------------------------------------------------
  # Received message types
  #---------------------------------------------------------------------------

  defmodule Call do
    defstruct ~w(mfa info from_pid from_mfa time)a

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      pid = printing_inspect(struct.from_pid)
      from_mfa = MFA.represent(struct.from_mfa)
      mfa = MFA.represent(struct.mfa)

      "# #{ts} #{pid} #{from_mfa}\n# #{mfa}"
    end
  end

  defmodule Return do
    defstruct ~w(mfa return_value from_pid from_mfa time)a

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      pid = printing_inspect(struct.from_pid)
      from_mfa = MFA.represent(struct.from_mfa)
      mfa = MFA.represent(struct.mfa)
      retn = printing_inspect(struct.return_value)

      "# #{ts} #{pid} #{from_mfa}\n# #{mfa} -> #{retn}"
    end
  end

  defmodule Send do
    defstruct ~w(msg to_pid to_mfa from_pid from_mfa time)a

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      to_pid = printing_inspect(struct.to_pid)
      to_mfa = MFA.represent(struct.to_mfa)
      from_pid = printing_inspect(struct.from_pid)
      from_mfa = MFA.represent(struct.from_mfa)
      msg = printing_inspect(struct.msg)

      "# #{ts} #{from_pid} #{from_mfa}\n# #{to_pid} #{to_mfa} <<< #{msg}"
    end
  end

  defmodule Receive do
    defstruct ~w(msg to_pid to_mfa time)a

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      to_pid = printing_inspect(struct.to_pid)
      to_mfa = MFA.represent(struct.to_mfa)
      msg = printing_inspect(struct.msg)

      "# #{ts} #{to_pid} #{to_mfa}\n# <<< #{msg}"
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


  def from_erl({:call, {mfa, info}, {from_pid, from_mfa}, time}) do
    %Call{
      mfa: MFA.from_erl(mfa),
      info: info,
      from_pid: from_pid,
      from_mfa: MFA.from_erl(from_mfa),
      time: Timestamp.from_erl(time)
    }
  end

  def from_erl({:retn, {mfa, retn}, {from_pid, from_mfa}, time}) do
    %Return{
      mfa: MFA.from_erl(mfa),
      return_value: retn,
      from_pid: from_pid,
      from_mfa: MFA.from_erl(from_mfa),
      time: Timestamp.from_erl(time),
    }
  end

  def from_erl({:send, {msg, {to_pid, to_mfa}}, {from_pid, from_mfa}, time}) do
    %Send{
      msg: msg,
      to_pid: to_pid,
      to_mfa: MFA.from_erl(to_mfa),
      from_pid: from_pid,
      from_mfa: MFA.from_erl(from_mfa),
      time: Timestamp.from_erl(time),
    }
  end

  def from_erl({:recv, msg, {to_pid, to_mfa}, time}) do
    %Receive{
      msg: msg,
      to_pid: to_pid,
      to_mfa: MFA.from_erl(to_mfa),
      time: Timestamp.from_erl(time),
    }
  end

  def from_erl(other) do
    other
  end

  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp represent(%mod{} = struct) when mod in [Call, Return, Send, Receive] do
    mod.represent(struct)
  end

end
