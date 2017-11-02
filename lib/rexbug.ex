defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """

  alias Rexbug.Translator


  @spec start(String.t, Keyword.t)
  :: {:ok, {integer, integer}} | {:error, term}

  def start(trace_pattern, options \\ []) do
    with {:ok, translated} <- Translator.translate(trace_pattern)
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
