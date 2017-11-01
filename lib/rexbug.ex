defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """



  def start(trace_pattern, actions) do
    
  end

  def stop() do
    :redbug.stop()
  end


  def help() do
    # TODO replace with own help with elixir syntax
    :redbug.help()
  end


end
