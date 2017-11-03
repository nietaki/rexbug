defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """

  alias Rexbug.Translator

  @type redbug_non_blocking_return :: {proc_count :: integer, func_count :: integer}
  @type redbug_blocking_return     :: {stop_reason :: atom, trace_messages :: [term]}
  @type redbug_error               :: {error_type :: atom, error_reason :: term}
  @type rexbug_error               :: {:error, reason :: term}

  @type rexbug_return :: redbug_non_blocking_return | redbug_blocking_return | redbug_error | rexbug_error

  @type proc  :: pid() | atom | {pid, integer, integer}
  @type procs :: :all | :new | :running | proc | [proc]

  @spec start(trace_pattern :: String.t) :: rexbug_return
  def start(trace_pattern), do: start(trace_pattern, [])

  @spec start(time :: integer, msgs :: integer, trace_pattern :: String.t) :: rexbug_return
  def start(time, msgs, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs])

  @spec start(time :: integer, msgs :: integer, procs :: procs, trace_pattern :: String.t) :: rexbug_return
  def start(time, msgs, procs, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs, procs: procs])

  @spec start(time :: integer, msgs :: integer, procs :: procs, node :: node(), trace_pattern :: String.t) :: rexbug_return
  def start(time, msgs, procs, node, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs, procs: procs, target: node])

  @spec start(trace_pattern :: String.t, opts :: Keyword.t) :: rexbug_return
  def start(trace_pattern, options) do
    with {:ok, options} <- Translator.translate_options(options),
         {:ok, translated} <- Translator.translate(trace_pattern)
      do
      :redbug.start(translated, options)
    end
  end


  def stop() do
    :redbug.stop()
  end

  # kind of relies on redbug internal behaviour, but not really
  def stop_sync(timeout \\ 100) do
    case Process.whereis(:redbug) do
      nil -> :not_started
      pid ->
        ref = Process.monitor(pid)
        :redbug.stop()
        receive do
          {:DOWN, ^ref, _, _, _} -> :stopped
        after
          timeout -> {:error, :could_not_stop_redbug}
        end
    end
  end


  def help() do
    # TODO replace with own help with elixir syntax
    :redbug.help()
  end


end
