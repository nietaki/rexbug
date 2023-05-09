defmodule Rexbug.Dtop do
  @moduledoc """
  This module implements `Rexbug.dtop/0`

  `dtop` provides much of the functionality of
  [observer](https://www.erlang.org/doc/man/observer.html),
  with an interface similar to and Linux's [htop](https://en.wikipedia.org/wiki/Htop)

  It's helpful in investigating the load on the machine and investigating any degradation
  in performance.

  Example infromation printed by `dtop`:

  ```txt
  -------------------------------------------------------------------------------
  nonode@nohost   size: 53.2M(3.2G), cpu%: 90(271), procs: 379, runq: 0, 21:02:17
  memory:      proc   16.9M, atom  950.5k, bin  398.6k, code   21.0M, ets    1.8M

  pid            name                         current             msgq    mem cpu
  <0.471.0>      'Elixir.Phoenix.CodeReloader gen_server:loop/7      0 264.1k  20
  <0.2.0>        erts_literal_area_collector: erts_literal_area      0  44.2k  18
  <0.1.0>        erts_code_purger             erts_code_purger:      0  39.7k  18
  <0.50.0>       code_server                  code_server:loop/      0   2.9M   7
  <0.10.0>       erl_prim_loader              erl_prim_loader:l      0 142.9k   5
  <0.669.0>      redbug_dtop                  redbug_dtop:prc_i      0 748.2k   3
  <0.60.0>       file_server_2                gen_server:loop/7      0  13.9k   1
  <0.67.0>       group:server/3               group:more_data/6      0   4.7M   1
  <0.671.0>      cowboy_clear:connection_proc cowboy_http:loop/      0  34.5k   0
  <0.120.0>      'Elixir.Mix.ProjectStack'    gen_server:loop/7      0  26.8k   0
  <0.65.0>       user_drv                     user_drv:server_l      0  26.8k   0
  <0.44.0>       application_controller       gen_server:loop/7      0 691.2k   0
  <0.168.0>      'Elixir.Hex.State'           gen_server:loop/7      0 743.9k   0
  <0.345.0>      'Elixir.Logger'              gen_event:fetch_m      0  18.9k   0
  <0.681.0>      cowboy_clear:connection_proc cowboy_http:loop/      0  13.7k   0
  <0.76.0>       disk_log_server              gen_server:loop/7      0  42.5k   0
  <0.75.0>       disk_log_sup                 gen_server:loop/7      0  24.8k   0
  <0.3.0>        erts_dirty_process_signal_ha erts_dirty_proces      0   2.6k   0
  <0.560.0>      ranch_conns_sup:init/4       ranch_conns_sup:l      0   9.3k   0
  ```

  As you can see, the output is separated into two sections: the header containing
  node information and the process table containing some information per process.

  ### Node information header

  All examples taken from the output example above.

  | example | name   | description |
  | --- | --- | --- |
  | `nonode@nohost` | node name | See `Node.self/0` |
  | `size: 53.2M` | allocated memory |  The total amount of memory currently allocated. This is the same as the sum of the memory size for processes and system. See `:erlang.memory/0` |
  | `(3.2G)` | Virtual Memory Size | value as `ps -o CMD,VSZ`, more info [here](https://stackoverflow.com/a/21049737/246337) |
  | `cpu%: 90` | CPU time used | Percentage of CPU time used by the BEAM, where 100% is equivalent to one core being used all the time (UTIME + STIME) |
  | `(271)` | total CPU time used | Total percentage of CPU time consumed on the machine, where 100% is equivalent to one core being used all the time |
  | `procs: 379` | process count | total number of processes running on the BEAM, See [`:erlang.system_info(:process_count)`](https://www.erlang.org/doc/man/erlang.html#system_info-1) |
  | `runq: 0` | run queue length | Total length of all normal and dirty CPU run queues - queuead work that is expected to be CPU bound. See [`:erlang.statistics(:run_queue)`](https://www.erlang.org/doc/man/erlang.html#statistics-1) |
  | `21:02:17` | local time |  |
  | `proc   16.9M` | Erlang process memory | The total amount of memory allocated for the Erlang processes. See [`:erlang.memory(:processes)`](https://www.erlang.org/doc/man/erlang.html#memory-1) |
  | `atom  950.5k` | Erlang atom memory | The total amount of memory allocated for atoms. See [`:erlang.memory(:atom)`](https://www.erlang.org/doc/man/erlang.html#memory-1) |
  | `bin  398.6k` | Erlang binary memory | The total amount of memory allocated for binaries. See [`:erlang.memory(:binary)`](https://www.erlang.org/doc/man/erlang.html#memory-1) |
  | `code   21.0M` | Erlang code memory | The total amount of memory allocated for Erlang/Elixir code. See [`:erlang.memory(:code)`](https://www.erlang.org/doc/man/erlang.html#memory-1) |
  | `ets    1.8M` | Erlang ETS memory | The total amount of memory allocated for ETS tables. See [`:erlang.memory(:code)`](https://www.erlang.org/doc/man/erlang.html#memory-1) |


  ### Process info table

  Most of the information in the process info table is the same as the information returned by `Process.info/1`. You can follow the docs there for more in-depth explanataions.

  | name | example   | description |
  | `pid` | `<0.345.0>` | the [PID](https://elixir-lang.org/getting-started/processes.html#spawn) (process identifier) of the process |
  | `name` | `'Elixir.Logger'` | The name of the process if the process is registered (See `Process.register/2`. Otherwise, the "initial call" - the initial function call with which the process was spawned. |
  | `current` | `gen_event:fetch_m` | The current function being executed by the process. |
  | `msgq` | `0` | The message queue length for the process.  |
  | `mem` | `18.9k` | The memory size of the process. This includes call stack, heap, and internal structures |
  | `cpu` | `7` | Estimated percentage CPU time used by the process. The `cpu` values for all PIDs would sum up to the `cpu%` (CPU time used) from the header. |
  """
  @compile {:inline, toggle_doc: 0}

  @type sort_type() :: :msgs | :cpu | :mem
  @type opt() :: {:sort, sort_type()} | {:max_procs, integer()}

  @help_message """
  Starts/stops (toggles) dtop. See the `Rexbug.Dtop` module docs for more information

  When dtop is running it will periodically print most resource-intensive processes
  along with some node performance statistics.

  Example invocation:

      Rexbug.dtop([sort: :mem])

  ## Supported options

  **sort** chooses the sorting for the processes. Supported values are
  `:msgs`, `:cpu`, and `:mem` - all sorted in descending order.

  `sort` defaults to `:cpu`

  **max_procs** sets the maximum number of processes for which dtop should be run.

  If there's more than `max_procs` running on the machine, `dtop` dtop will
  not print any process info, just the header. This is to avoid oveloading the VM.

  `max_procs` defaults to `1_500`.
  """

  @toggle_doc @help_message

  @doc false
  def toggle_doc(), do: @toggle_doc

  @doc @toggle_doc
  @spec toggle([opt()] | %{}) :: term()
  def toggle(opts \\ [])

  def toggle(map) when is_map(map) do
    do_dtop(map)
  end

  def toggle(list) when is_list(list) do
    if Keyword.keyword?(list) do
      do_dtop(Map.new(list))
    else
      print_help()
    end
  end

  def toggle(_), do: print_help()

  defp do_dtop(map) when is_map(map) do
    :redbug.dtop(map)
  end

  defp print_help() do
    IO.puts(toggle_doc())
    {:error, :invalid_invocation}
  end
end
