defmodule Rexbug do
  @moduledoc """
  A thin Elixir wrapper for the redbug Erlang tracing debugger.
  """

  @help_message """

  Rexbug - a thin Elixir wrapper for :redbug - the (sensibly) Restrictive
  Debugger. It doesn't fork :redbug, only uses it under the hood.

  You can use :redbug directly - run :redbug.help() to see its help message.

  Inner workings:
    Rexbug is a tool to interact with the Erlang trace facility.
    It will instruct the Erlang VM to generate so called
    "trace messages" when certain events (such as a particular
    function being called) occur.
    The trace messages are either printed (i.e. human readable)
    to a file or to the screen; or written to a trc file.
    Using a trc file puts less stress on the system, but
    there is no way to count the messages (so the msgs opt
    is ignored), and the files can only be read by special tools
    (such as 'bread'). Printing and trc files cannot be combined.
    By default (i.e. if the :file opt is not given), messages
    are printed.


  Basic usage:
    Rexbug.start(trace_pattern, opts \\ [])
    Rexbug.start(time_limit, message_limit, trace_pattern)

  trace_pattern:  :send | :receive | rtp | [:send | :receive | rtp]

  rtp:  restricted trace pattern
    the rtp has the form: "<mfa> when <guards> :: <actions>"
    where <mfa> can be:
      "Mod", "Mod.fun/3", "Mod.fun/_" or "Mod.fun(_, :atom, x)"

    <guard> is something like:
      "x==1" or "is_atom(A)"

    and <actions> is:
      "", "return", "stack", or "return;stack"

    E.g.
      :ets.lookup(t, :hostname) when is_integer(t) :: stack
      Map.new/2
      Map.pop(_, :some_key, default) when default != nil :: return
      Agent

  NOTE: The <mfa> of "Map.new" is equivalent to "Map.new()" - the 0 arity
  is implied. To trace the function with any arity use "Map.new/any" or
  simply "Map.new/_".

  opts: Keyword.t
    general opts (and their default values):

  time         (15000)       stop trace after this many ms
  msgs         (10)          stop trace after this many msgs
  target       (Node.self()) node to trace on
  cookie       (host cookie) target node cookie
  blocking     (false)       block start/2, return a list of messages
  arity        (false)       print arity instead of arg list
  buffered     (false)       buffer messages till end of trace
  discard      (false)       discard messages (when counting)
  max_queue    (5000)        fail if internal queue gets this long
  max_msg_size (50000)       fail if seeing a msg this big
  procs        (:all)        (list of) Erlang process(es)
                              :all|pid()|atom(reg_name)|{:pid,i2,i3}
    print-related opts:
  print_calls  (true)        print calls
  print_file   (standard_io) print to this file
  print_msec   (false)       print milliseconds on timestamps
  print_depth  (999999)      formatting depth for "~P"
  print_re     ("")          print only messages that match this regex
  print_return (true)        print return value (if "return" action given)
  print_fun    ()            custom print handler, fun/1 or fun/2;
                              fun(trace_msg :: term) :: <ignored>
                              fun(trace_msg, acc_old) :: acc_new
                             (where initial accumulator is 0)
    trc file related opts:
  file         (none)        use a trc file based on this name
  file_size    (1)           size of each trc file
  file_count   (8)           number of trc files
  """


  alias Rexbug.Translator

  @type redbug_non_blocking_return :: {proc_count :: integer, func_count :: integer}
  @type redbug_blocking_return     :: {stop_reason :: atom, trace_messages :: [term]}
  @type redbug_error               :: {error_type :: atom, error_reason :: term}
  @type rexbug_error               :: {:error, reason :: term}

  @type rexbug_return :: redbug_non_blocking_return | redbug_blocking_return | redbug_error | rexbug_error

  @type trace_pattern_instance :: String.t | :send | :receive

  @type trace_pattern :: trace_pattern_instance | [trace_pattern_instance]

  @type proc  :: pid() | atom | {pid, integer, integer}
  @type procs :: :all | :new | :running | proc | [proc]

  @spec start(trace_pattern) :: rexbug_return
  def start(trace_pattern), do: start(trace_pattern, [])

  @spec start(time :: integer, msgs :: integer, trace_pattern) :: rexbug_return
  def start(time, msgs, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs])

  @spec start(time :: integer, msgs :: integer, procs :: procs, trace_pattern) :: rexbug_return
  def start(time, msgs, procs, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs, procs: procs])

  @spec start(time :: integer, msgs :: integer, procs :: procs, node :: node(), trace_pattern) :: rexbug_return
  def start(time, msgs, procs, node, trace_pattern), do: start(trace_pattern, [time: time, msgs: msgs, procs: procs, target: node])

  @spec start(trace_pattern, opts :: Keyword.t) :: rexbug_return
  @doc """
  Starts tracing for the given pattern with provided options.
  """
  def start(trace_pattern, options) do
    with {:ok, options} <- Translator.translate_options(options),
         {:ok, translated} <- Translator.translate(trace_pattern)
      do
      :redbug.start(translated, options)
    end
  end


  @spec stop() :: :stopped | :not_started
  @doc """
  Stops all tracing.
  """
  def stop() do
    :redbug.stop()
  end

  @spec stop_sync() :: :stopped | :not_started | {:error, :could_not_stop_redbug}
  @doc """
  Stops all tracing in a synchronous manner.

  Usually there's no need to use this function over `stop/0`. You might want to use
  it if you're going to start tracing immediately afterwards in an automated fashion.
  """
  # kind of relies on redbug internal behaviour, but not really
  def stop_sync(timeout \\ 100) do
    case Process.whereis(:redbug) do
      nil -> :not_started
      pid ->
        ref = Process.monitor(pid)
        res = :redbug.stop()
        receive do
          {:DOWN, ^ref, _, _, _} ->
            :stopped
            res
        after
          timeout -> {:error, :could_not_stop_redbug}
        end
    end
  end

  @spec help() :: :ok
  @doc """
  Prints the help message / usage manual to standard output.

  The help message is as follows:

  ```txt
  """ <>
    @help_message <>
    "\n```"

  def help() do
    IO.puts(@help_message)
    :ok
  end


end
