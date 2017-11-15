![rexbug logo](assets/logo_horizontal_h150px.png)

`Rexbug` is a thin Elixir wrapper for [`:redbug`](https://hex.pm/packages/redbug) 
production-safe Erlang tracing debugger. 
It tries to preserve [`:redbug`](https://hex.pm/packages/redbug)'s simple and 
intuitive interface while making it more convenient to use by Elixir developers.

[![travis badge](https://travis-ci.org/nietaki/rexbug.svg?branch=master)](https://travis-ci.org/nietaki/rexbug)
[![Coverage Status](https://coveralls.io/repos/github/nietaki/rexbug/badge.svg?branch=master)](https://coveralls.io/github/nietaki/rexbug?branch=master) 
[![Hex.pm](https://img.shields.io/hexpm/v/rexbug.svg)](https://hex.pm/packages/rexbug) 
[![docs](https://img.shields.io/badge/docs-hexdocs-yellow.svg)](https://hexdocs.pm/rexbug/) 
[![Built with Spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org)

# README

## How does it work?

Rexbug uses unmodified [`:redbug`](https://hex.pm/packages/redbug) library underneath.
It translates Elixir syntax to the Erlang format expected by 
[`:redbug`](https://hex.pm/packages/redbug).

[`:redbug`](https://hex.pm/packages/redbug) in turn interacts with the Erlang trace facility.
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
  [{:rexbug, "~> 0.1.0"}]
end
```

After you've added `Rexbug` to your project, there's nothing left to do - you 
can start debugging it at your convenience.

## Motivation

* TODO

## Examples

* TODO

## `:redbug` syntax comparison

If you want to move between `:redbug` and `Rexbug` or you're just curious how
they compare, here's some examples:

| `Rexbug` in Elixir | `:redbug` in Elixir | `redbug` in Erlang |
| --- | --- | --- |
| `Rexbug.start(":ets")` | `:redbug.start('ets')` |  `redbug:start("ets")` |
| `Rexbug.stop()` | `:redbug.stop()` | `redbug:stop()` |


* TODO (remember to have some cases with strings)

## Known issues

* TODO

- guards aren't supported (yet) - [relevant issue](https://github.com/nietaki/rexbug/issues/1)
- doesn't support map matching
- `Mod.fun` is `Mod.fun/0`

## FAQ

### How do I use it with my mix project?

* TODO

### How do I use it on an already running system?

* TODO

### How does Rexbug compare with other Elixir debuggers?

* TODO

### Why "translate" the syntax instead of forking `:redbug` and caling its internals directly?

* TODO

- the performance penalty should be irrelevant
- you can still use redbug directly
- "time to market"
- I might reconsider and do it, right now I don't want to mess with a good thing
