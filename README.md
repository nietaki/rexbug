![rexbug logo](assets/logo_horizontal_h150px.png)

![Hex.pm](https://img.shields.io/hexpm/v/rexbug)
[![Hex.pm](https://img.shields.io/hexpm/dt/rexbug)](https://hex.pm/packages/rexbug)
![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/nietaki/rexbug/test.yml?label=tests)
![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/nietaki/rexbug/style_check.yml?label=style%20check)
[![Coverage Status](https://coveralls.io/repos/github/nietaki/rexbug/badge.svg)](https://coveralls.io/github/nietaki/rexbug)
[![docs](https://img.shields.io/badge/docs-hexdocs-yellow.svg)](https://hexdocs.pm/rexbug/)

`Rexbug` is a thin Elixir wrapper for [`:redbug`](https://hex.pm/packages/redbug)
production-friendly Erlang tracing debugger.
It tries to preserve [`:redbug`](https://hex.pm/packages/redbug)'s simple and
intuitive interface while making it more convenient to use by Elixir developers.

# README

## What does it do?

It's an Elixir [tracing](https://en.wikipedia.org/wiki/Tracing_(software)) -
based debugger. It allows you to connect to a live Elixir system and get
information when some code inside it is executed. The "some code" can be a
whole module, a specific function in the module, or some function, but only
if it's called with some specific arguments. The information you can get
is the function arguments, its result and the stack trace.

If you want to you can narrow the tracing down to a specific process,
investigate a remote node or look at the messages sent between processes.

Rexbug is also production-system-friendly. It has sensible limits for both time
and amount of trace events after which it stops tracing. This means you won't
accidentally overload the system and flood your console with debug information
if your trace pattern wasn't specific enough.

It also provides `Rexbug.dtop/1` - 
a tool with much of the functionality of
[observer](https://www.erlang.org/doc/man/observer.html),
with an interface similar to and Linux's [htop](https://en.wikipedia.org/wiki/Htop)

## How does it work?

Rexbug uses unmodified [`:redbug`](https://hex.pm/packages/redbug) library
underneath. It translates Elixir syntax to the Erlang format expected by
[`:redbug`](https://hex.pm/packages/redbug).

[`:redbug`](https://hex.pm/packages/redbug) in turn interacts with the
Erlang trace facility.
It will instruct the Erlang VM to generate so called
"trace messages" when certain events (such as a particular
function being called) occur.
The trace messages are either printed (i.e. human readable)
to a file or to the screen; or written to a trc file.
Using a trc file puts less stress on the system, but
there is no way to count the messages (so the msgs opt
is ignored), and the files can only be read by special tools
(such as 'bread'). Printing and trc files cannot be combined.
By default (i.e. if the `:file` opt is not given), messages
are printed.

## Installation

The package can be installed by adding `Rexbug` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:rexbug, ">= 2.0.0-rc1"}]
end
```

After you've added `Rexbug` to your project, there's nothing left to do - you
can start debugging it at your convenience.

## Examples

### Tracing a single function

The general syntax is `Rexbug.start("ModuleName.function_name/_")`.
The `/_` tells Rexbug we're interested in any arity of the function.

```elixir
iex(3)> Rexbug.start("Map.get/_ :: return") # asking for the return value too
{105, 2}
iex(4)> Map.get(%{}, :foo)
nil

# 10:49:02 #PID<0.1057.0> IEx.Evaluator.init/4
# Map.get(%{}, :foo)

# 10:49:02 #PID<0.1057.0> IEx.Evaluator.init/4
# Map.get(%{}, :foo, nil)

# 10:49:02 #PID<0.1057.0> IEx.Evaluator.init/4
# Map.get/3 -> nil

# 10:49:02 #PID<0.1057.0> IEx.Evaluator.init/4
# Map.get/2 -> nil
redbug done, timeout - 2
```

### Tracing a whole module

```elixir
iex> Rexbug.start("Map")
{82, 41}
iex> m = Map.put(%{}, :foo, :bar) # this could have been called in any process
%{foo: :bar}

# 18:51:55 #PID<0.150.0> IEx.Evaluator.init/4
# Map.__info__(:macros)
iex> Map.get(m, :foo)
:bar

# 18:51:57 #PID<0.150.0> IEx.Evaluator.init/4
# Map.__info__(:macros)

# 18:51:57 #PID<0.150.0> IEx.Evaluator.init/4
# Map.get(%{foo: :bar}, :foo)

# 18:51:57 #PID<0.150.0> IEx.Evaluator.init/4
# Map.get(%{foo: :bar}, :foo, nil)
iex> # Rexbug tracing is going to time out now
nil
redbug done, timeout - 4
iex>
```

### Tracing with matching function arguments

```elixir
iex> Rexbug.start("Enum.member?([_, _, _], \"foo\")")
{82, 1}
iex> Enum.member?([1, 2], "foo") # first argument doesn't match
false
iex> Enum.member?([1, 2, 3], "bar") # second argument doesn't match
false
iex> Enum.member?([1, 2, 3], "foo") # will match
false

# 18:55:44 #PID<0.150.0> IEx.Evaluator.init/4
# Enum.member?([1, 2, 3], "foo")
iex> Rexbug.stop()
:stopped
redbug done, local_done - 1
iex>
```

### Tracing messages sent and received from a process

```elixir
iex> s = self()
#PID<0.193.0>
iex> proc = Process.spawn(fn ->
...>   receive do
...>     anything -> send(s, {:got, anything})
...>   end
...> end, [])
iex> Rexbug.start([:send, :receive], procs: [proc], time: 60_000)
{1, 0}
iex> send(proc, :foo)
:foo

# 18:31:08 #PID<0.208.0> (:dead)
# <<< :foo

# 18:31:08 #PID<0.208.0> (:dead)
# #PID<0.193.0> IEx.Evaluator.init/4 <<< {:got, :foo}
iex> flush()
{:got, :foo}
:ok
redbug done, timeout - 2
```

### Running dtop

```elixir
iex(0)> Rexbug.dtop() # start dtop
{:ok, :started}
-------------------------------------------------------------------------------
nonode@nohost    size: 41.6M(420.4G), cpu%: 2(0), procs: 378, runq: 0, 12:27:41
memory:      proc    8.4M, atom  737.5k, bin    2.2M, code   15.9M, ets    1.7M

pid            name                         current             msgq    mem cpu
<0.685.0>      redbug_dtop                  redbug_dtop:prc_i      0 431.8k   2
<0.66.0>       group:server/3               group:more_data/6      0 176.4k   0
<0.64.0>       user_drv                     user_drv:server_l      0  26.5k   0
<0.10.0>       erl_prim_loader              erl_prim_loader:l      0 142.9k   0
<0.50.0>       code_server                  code_server:loop/      0 284.7k   0
<0.456.0>      inet_gethost_native          inet_gethost_nati      0  18.8k   0
<0.437.0>      Elixir.DBConnection.Connecti gen_server:loop/7      0  26.8k   0
<0.440.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.448.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.447.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.446.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.445.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.444.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.443.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.442.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.441.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.439.0>      Elixir.DBConnection.Connecti erlang:hibernate/      0   3.3k   0
<0.538.0>      cowboy_clock                 gen_server:loop/7      0  10.9k   0
<0.550.0>      telemetry_poller:init/1      gen_server:loop/7      0   3.0k   0

iex(3)> Rexbug.dtop(sort: :mem) # sort by memory
{:ok, :reconfigured}
-------------------------------------------------------------------------------
nonode@nohost    size: 43.4M(420.4G), cpu%: 1(0), procs: 378, runq: 0, 12:27:47
memory:      proc   10.1M, atom  737.5k, bin    2.6M, code   15.9M, ets    1.7M

pid            name                         current             msgq    mem cpu
<0.685.0>      redbug_dtop                  redbug_dtop:prc_i      0   1.8M   1
<0.44.0>       application_controller       gen_server:loop/7      0 691.1k   0
<0.521.0>      telemetry_poller_default     gen_server:loop/7      0 407.4k   0
<0.168.0>      'Elixir.Hex.State'           gen_server:loop/7      0 372.3k   0
<0.50.0>       code_server                  code_server:loop/      0 284.7k   0
<0.473.0>      Elixir.Postgrex.TypeServer:i gen_server:loop/7      0 264.4k   0
<0.66.0>       group:server/3               group:more_data/6      0 197.3k   0
<0.497.0>      Elixir.FileSystem.Backends.F gen_server:loop/7      0 176.3k   0
<0.10.0>       erl_prim_loader              erl_prim_loader:l      0 142.9k   0
<0.496.0>      phoenix_live_reload_file_mon gen_server:loop/7      0 142.8k   0
<0.82.0>       disk_log                     disk_log:loop/1        0 109.7k   0
<0.165.0>      'Elixir.Hex.Supervisor'      gen_server:loop/7      0  88.8k   0
<0.2.0>        erts_literal_area_collector: erts_literal_area      0  77.7k   0
<0.0.0>        init                         init:loop/1            0  42.3k   0
<0.1.0>        erts_code_purger             erts_code_purger:      0  35.5k   0
<0.682.0>      Elixir.IEx.Evaluator:init/4  Elixir.IEx.Evalua      0  34.4k   0
<0.578.0>      supervisor:ranch_acceptors_s erlang:hibernate/      0  30.7k   0
<0.64.0>       user_drv                     user_drv:server_l      0  26.8k   0
<0.456.0>      inet_gethost_native          inet_gethost_nati      0  26.7k   0

iex(4)> Rexbug.dtop() # stop dtop
{:ok, :stopped}
```

For more info and advanced usage see `Rexbug.Dtop` module docs.

## Motivation

I was discussing investigating some unexpected behaviour in an Elixir project with
[one of my colleagues](https://github.com/sylane) and he rightfully suggested
using a tracing debugger to get to the bottom of it. The tool he had the most
experience with was `:redbug` and it soon turned out it's possible to use from
`iex` and with Elixir code, as long as you know some Erlang and are mindful
of some gotchas.

I really liked how `:redbug` was designed, but wished using it with Elixir was
more streamlined...

## `:redbug` syntax comparison

If you want to move between `:redbug` and `Rexbug` or you're just curious how
they compare, here's some examples:

```elixir
# tracing an Erlang module
Rexbug.start(":ets")
:redbug.start('ets')

# stopping
Rexbug.stop()
:redbug.stop()

# tracing with arguments matching (and strings)
Rexbug.start("String.starts_with?(_, \"foo\")") # you can use the ~s sigil so that you don't have to escape the quotes
:redbug.start('\'Elixir.String\':\'starts_with?\'(_, <<"foo">>)')

# selecting the actions
Rexbug.start("Map.new/_ :: return;stack")
:redbug.start('\'Elixir.Map\':new -> return;stack')

```

## Known issues/limitations

- In the trace patterns `"Mod.fun"` implicitly translates to `"Mod.fun()"`, which
  is equivalent to `"Mod.fun/0"`. To target the function with any arity, use
  `"Mod.fun/_"` or `"Mod.fun/any"`

## FAQ

### Which versions of Elixir and Erlang/OTP does Rexbug support?

- Elixir 1.11.4 and newer 
- Erlang/OTP 24 and newer 

**If you're targeting an older system, try Rexbug 1.x, which handles Elixir 1.4 and newer**

Make sure to check the [general Erlang/Elixir compatibility table](https://hexdocs.pm/elixir/1.15.4/compatibility-and-deprecations.html#compatibility-between-elixir-and-erlang-otp)


### My app is already running and it doesn't have Rexbug in its dependencies. Can I still debug it?

Yes! You can connect to it from a node that has Rexbug in its path and work from there.

The app:

```iex
nietaki@shiny:~$ iex --sname production --cookie monster
Erlang/OTP 20 [erts-9.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.4.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(production@shiny)1> Rexbug.help() # the node doesn't know about Rexbug
** (UndefinedFunctionError) function Rexbug.help/0 is undefined (module Rexbug is not available)
    Rexbug.help()
iex(production@shiny)2> Stream.interval(1000) |> Enum.each(&Integer.mod(&1, 3))

```

Your local shell:

```iex
nietaki@shiny:~$ iex --sname investigator --cookie monster -pa ~/repos/rexbug/_build/dev/lib/rexbug/ebin/ -pa ~/repos/rexbug/_build/dev/lib/redbug/ebin/
Erlang/OTP 20 [erts-9.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.4.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(investigator@shiny)1> opts = [target: :production@shiny, msgs: 4]
[target: :production@shiny, msgs: 4]
iex(investigator@shiny)2> Rexbug.start("Integer.mod/2", opts)
{63, 1}

% 23:53:44 <9548.89.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Integer':mod(46, 3)

% 23:53:45 <9548.89.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Integer':mod(47, 3)

% 23:53:46 <9548.89.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Integer':mod(48, 3)

% 23:53:47 <9548.89.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Integer':mod(49, 3)
redbug done, msg_count - 4
iex(investigator@shiny)3>
```

Instead of pointing to the `Rexbug` and `:redbug` beam files you can just clone
this repo and run `iex -S mix` in the root directory:

```iex
nietaki@shiny:rexbug (master=)$ iex --sname investigator --cookie monster -S mix
Erlang/OTP 19 [erts-8.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.4.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(investigator@shiny)1> opts = [target: :production@shiny, msgs: 4]
[target: :production@shiny, msgs: 4]
iex(investigator@shiny)2> Rexbug.start("Integer.mod/2", opts)
(...)
```

### How does Rexbug compare with other Elixir debuggers?

Good question! There are other projects that give you similar capabilities, like
[dbg](https://hex.pm/packages/dbg) by [@fishcakez](https://github.com/fishcakez)
or [exrun](https://hex.pm/packages/exrun), both of which look great and are
definitely more battle-tested than Rexbug.

I'll try to add a brief and unbiased (as much as I can) comparison after I've
[spent some time playing with them](https://github.com/nietaki/rexbug/issues/9)
so I can do make sure I know what I'm talking about.

### Why "translate" the syntax instead of forking `:redbug` and caling its internals directly?

There's a number of reasons:

- The performance overhead should be irrelevant. You pay the small additional cost
  once every time you run `Rexbug.start/2` and it should be negligible compared
  to whatever system you're debugging.
- Since `:redbug` is included as-is you can still use it directly and benefit
  from any new features it might get. Also if your team is split between people
  more comfortable in Erlang and Elixir, everyone can use what they prefer.
- "time to market" - doing this was the simplest way I could think of to get
  to a relatively polished library.
- This approach didn't seem to limit the possible featureset. All the
  `:redbug` features can still be provided.

In general there weren't enough reasons to do it the other way. I don't rule
out the possibility of a future rewrite, which wouldn't be too drastic anyways.
