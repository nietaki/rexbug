![rexbug logo](assets/logo_horizontal_h150px.png)

`Rexbug` is a thin Elixir wrapper for [`:redbug`](https://hex.pm/packages/redbug) 
production-friendly Erlang tracing debugger. 
It tries to preserve [`:redbug`](https://hex.pm/packages/redbug)'s simple and 
intuitive interface while making it more convenient to use by Elixir developers.

[![travis badge](https://travis-ci.org/nietaki/rexbug.svg?branch=master)](https://travis-ci.org/nietaki/rexbug)
[![Coverage Status](https://coveralls.io/repos/github/nietaki/rexbug/badge.svg?branch=master)](https://coveralls.io/github/nietaki/rexbug?branch=master) 
[![Hex.pm](https://img.shields.io/hexpm/v/rexbug.svg)](https://hex.pm/packages/rexbug) 
[![docs](https://img.shields.io/badge/docs-hexdocs-yellow.svg)](https://hexdocs.pm/rexbug/) 
[![Built with Spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org)

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
  [{:rexbug, ">= 0.5.0"}]
end
```

After you've added `Rexbug` to your project, there's nothing left to do - you 
can start debugging it at your convenience.

## Examples

```Elixir
iex> Rexbug.start("Map") # trace the whole module
{82, 41}
iex> m = Map.put(%{}, :foo, :bar) # this could have been called in any process

% 23:40:49 <0.147.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Map':'__info__'(macros)
%{foo: :bar}
iex> Map.get(m, :foo)
:bar

% 23:40:53 <0.147.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Map':'__info__'(macros)

% 23:40:53 <0.147.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Map':get(#{foo => bar}, foo)

% 23:40:53 <0.147.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Map':get(#{foo => bar}, foo, nil)
iex> # Rexbug tracing is going to time out now
nil
redbug done, timeout - 4
iex>
```

```Elixir
iex> Rexbug.start("Enum.member?([_, _, _], \"foo\")") # trace function with matching arguments
{82, 1}
iex> Enum.member?([1, 2], "foo") # first argument doesn't match
false
iex> Enum.member?([1, 2, 3], "bar") # second argument doesn't match
false
iex> Enum.member?([1, 2, 3], "foo") # will match
false

% 23:48:07 <0.147.0>({'Elixir.IEx.Evaluator',init,4})
% 'Elixir.Enum':'member?'([1,2,3], <<"foo">>)
iex> Rexbug.stop()
:stopped
redbug done, local_done - 1
iex>
```

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

```Elixir
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

- It's not possible to pattern match on maps in the function args - 
  I'm reasonably sure it's a [limitation of `:redbug`](https://github.com/massemanet/redbug/issues/2)
- In the trace patterns `"Mod.fun"` implicitly translates to `"Mod.fun()"`, which
  is equivalent to `"Mod.fun/0"`. To target the function with any arity, use 
  `"Mod.fun/_"` or `"Mod.fun/any"` 

## FAQ

<!-- ### How do I use it with my mix project? -->

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
