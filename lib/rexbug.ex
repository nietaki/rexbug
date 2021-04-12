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
      "x==1" or "is_atom(a)"

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

  time         (15_000)      stop trace after this many ms
  msgs         (10)          stop trace after this many msgs
  target       (Node.self()) node to trace on
  cookie       (host cookie) target node cookie
  blocking     (false)       block start/2, return a list of messages
  arity        (false)       print arity instead of arg list
  buffered     (false)       buffer messages till end of trace
  discard      (false)       discard messages (when counting)
  max_queue    (5_000)       fail if internal queue gets this long
  max_msg_size (50_000)      fail if seeing a msg this big
  procs        (:all)        (list of) Erlang process(es)
                              :all|:new|pid()|atom(reg_name)|{:pid,i2,i3}
    print-related opts:
  print_calls  (true)        print calls
  print_file   (standard_io) print to this file
  print_msec   (false)       print milliseconds on timestamps
  print_depth  (999_999)     formatting depth for "~P"
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
  @type redbug_blocking_return :: {stop_reason :: atom, trace_messages :: [term]}
  @type redbug_error :: {error_type :: atom, error_reason :: term}
  @type rexbug_error :: {:error, reason :: term}

  @type rexbug_return ::
          redbug_non_blocking_return | redbug_blocking_return | redbug_error | rexbug_error

  @type trace_pattern_instance :: String.t() | :send | :receive

  @type trace_pattern :: trace_pattern_instance | [trace_pattern_instance]

  @type proc :: pid() | atom | {pid, integer, integer}
  @type procs :: :all | :new | :running | proc | [proc]

  @spec start(trace_pattern) :: rexbug_return
  @doc """
  See `Rexbug.start/2`.
  """
  def start(trace_pattern), do: start(trace_pattern, [])

  @spec start(time :: integer, msgs :: integer, trace_pattern) :: rexbug_return
  @doc """
  See `Rexbug.start/2`.
  """
  def start(time, msgs, trace_pattern), do: start(trace_pattern, time: time, msgs: msgs)

  @spec start(time :: integer, msgs :: integer, procs :: procs, trace_pattern) :: rexbug_return
  @doc """
  See `Rexbug.start/2`.
  """
  def start(time, msgs, procs, trace_pattern),
    do: start(trace_pattern, time: time, msgs: msgs, procs: procs)

  @spec start(time :: integer, msgs :: integer, procs :: procs, node :: node(), trace_pattern) ::
          rexbug_return
  @doc """
  See `Rexbug.start/2`.
  """
  def start(time, msgs, procs, node, trace_pattern),
    do: start(trace_pattern, time: time, msgs: msgs, procs: procs, target: node)

  @spec start(trace_pattern, opts :: Keyword.t()) :: rexbug_return
  @doc """
  Starts tracing for the given pattern with provided options.

  If successful and `:blocking` option is not specified, returns a tuple
  where the first element is the count of targeted processes and the
  second element is the count of targeted functions

  # Trace Pattern
  The `trace_pattern` is a string (binary) describing which function(s)
  should be traced.

  The `trace_pattern` has the `"<mfa> when <guards> :: <actions>"` form,
  where guards and actions are optional and &lt;mfa&gt; can be in the form of
  `Mod`, `Mod.fun/3`, `Mod.fun/_` or `Mod.fun(_, :atom, x)`

  Most normal [Elixir guards](https://hexdocs.pm/elixir/master/guards.html)
  are valid as &lt;guards&gt;, so something like
  `x==1` or `is_atom(x)` or `is_integer(i) and i > 0` would work.

  The valid &lt;actions&gt; are: `return`, `stack`, or `return;stack`

  Apart from tracing function calls you can trace sent and received messages.
  To do so specify `:send` or `:receive` as the trace pattern.

  You can also specify multiple trace patterns by providing a list of them
  as the first argument.

  # Options

  There's a range of options that modify the behaviour of `Rexbug`.


  ## General options

  | option         | default       | meaning                                                                             |
  | ---            | ---           | ---                                                                                 |
  | time           | `15_000`      | stop tracing after this many milliseconds                                           |
  | msgs           | `10`          | stop tracing after this many messages                                               |
  | target         | `Node.self()` | node to trace on                                                                    |
  | cookie         | host cookie   | target node cookie                                                                  |
  | blocking       | `false`       | block on `start/2` and return a list of messages. [see comment](#start/2-blocking)  |
  | arity          | `false`       | print arity instead of argument list                                                |
  | buffered       | `false`       | buffer messages till end of trace                                                   |
  | discard        | `false`       | discard messages (when counting)                                                    |
  | max_queue      | `5_000`       | fail if internal queue gets this long                                               |
  | max\_msg\_size | `50_000`      | fail if seeing a message this big                                                   |
  | procs          | `:all`        | (list of) Erlang process(es) to include when tracing. [see comment](#start/2-procs) |

  ## Print-related options
  | option       | default     | meaning                                                                                         |
  | ---          | ---         | ---                                                                                             |
  | print_calls  | `true`      | print calls                                                                                     |
  | print_file   | standard_io | if provided, prints messages to the specified file                                              |
  | print_msec   | `false`     | print milliseconds on timestamps                                                                |
  | print_depth  | `999_999`   | formatting depth for `"~P"`                                                                     |
  | print_re     | `""`        | print only messages that match this regex                                                       |
  | print_return | `true`      | if set to `false`, won't print the return values. Relevant only if `return` action is specified |
  | print_fun    | none        | Custom print handler. [see comment](#start/2-print_fun)                                         |

  ## Trace file related options

  | option     | default | meaning                           |
  | ---        | ---     | ---                               |
  | file       | none    | use a trc file based on this name |
  | file_size  | `1`     | size of each trc file             |
  | file_count | `8`     | number of trc files               |

  ## Options comments

  ### `:blocking`

  If set to true, instead of printing traces to stdio, `Rexbug.start/2` will block
  and return a list of trace messages when it's done tracing.

  ### `:procs`

  Which processes to trace. The possible values are `:all` for all processes,
  `:new` for just the ones spawned after the tracing has started,
  an atom for registered processes, or a pid. The pid can either be a PID
  literal or a `{:pid, x, y}`, where `x` and `y` are the latter 2 integers from
  the PID representation. So for example `#PID<0.150.0>` could be expressed with
  `{:pid, 150, 0}`.

  The first integer from the PID representation is omitted, because it represents
  the node number. You can use the `target` option to specify a remote node instead.

  You can provide either a single process or a list of procs to trace.

  ### `:print_fun`

  Custom function to use to print the trace messages.

  The function can be in the `fun(trace_msg :: term) :: <ignored>` format
  or the `fun(trace_msg, acc_old) :: acc_new` format. If you use the latter format,
  the initial accumulator will be `0`.
  """
  def start(trace_pattern, options) do
    with {:ok, options} <- Translator.translate_options(options),
         options = add_default_options(options),
         {:ok, translated} <- Translator.translate(trace_pattern) do
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

  @spec stop_sync(integer) :: :stopped | :not_started | {:error, :could_not_stop_redbug}
  @doc """
  Stops all tracing in a synchronous manner.

  Usually there's no need to use this function over `stop/0`. You might want to use
  it if you're going to start tracing immediately afterwards in an automated fashion.
  """
  # kind of relies on redbug internal behaviour, but not really
  def stop_sync(timeout \\ 100) do
    case Process.whereis(:redbug) do
      nil ->
        :not_started

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
       """ <> @help_message <> "\n```"

  def help() do
    IO.puts(@help_message)
    :ok
  end

  defp add_default_options(opts) do
    print_fun = fn t -> Rexbug.Printing.print_with_opts(t, opts) end

    default_options = [
      print_fun: print_fun
    ]

    Keyword.merge(default_options, opts)
  end
end
