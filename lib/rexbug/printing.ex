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
      a
      |> Atom.to_string()
      |> String.upcase()
    end

    def represent(%__MODULE__{m: m, f: f, a: a}) do
      mrep = case Atom.to_string(m) do
        "Elixir." <> rest -> rest
        erlang_module -> ":#{erlang_module}"
      end

      # TODO use a version of inspect that doesn't truncate stuff
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
      :time,
    ]

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      pid = inspect(struct.from_pid)
      from_mfa = MFA.represent(struct.from_mfa)
      mfa = MFA.represent(struct.mfa)

      "# #{ts} #{pid} #{from_mfa}\n# #{mfa}"
    end
  end

  defmodule Return do
    defstruct [
      :mfa,
      :return_value,
      :from_pid,
      :from_mfa,
      :time,
    ]

    def represent(%__MODULE__{} = struct) do
      ts = Timestamp.represent(struct.time)
      pid = inspect(struct.from_pid)
      from_mfa = MFA.represent(struct.from_mfa)
      mfa = MFA.represent(struct.mfa)
      retn = inspect(struct.return_value)

      "# #{ts} #{pid} #{from_mfa}\n# #{mfa} -> #{retn}"
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
    %Call{
      mfa: MFA.from_erl(mfa),
      info: info,
      from_pid: from_pid,
      from_mfa: MFA.from_erl(from_mfa),
      time: Timestamp.from_erl(time)
    }
  end

  # {
  #   :retn,
  #   {
  #    {URI, :parse, 1},
  #     %URI{authority: "example.com", fragment: nil, host: "example.com", path: nil,
  #          port: 443, query: nil, scheme: "https", userinfo: nil}
  #   },
  #   {
  #     #PID<0.194.0>,
  #     :dead
  #   },
  #   {21, 53, 7, 178179}
  # }

  def from_erl({:retn, {mfa, retn}, {from_pid, from_mfa}, time}) do
    %Return{
      mfa: MFA.from_erl(mfa),
      return_value: retn,
      from_pid: from_pid,
      from_mfa: MFA.from_erl(from_mfa),
      time: Timestamp.from_erl(time),
    }
  end

  def from_erl(other) do
    other
  end


  defp represent(%mod{} = struct) when mod in [Call, Return] do
    mod.represent(struct)
  end

  defp represent(other) do
    "OTHER: " <> inspect(other)
  end


end
