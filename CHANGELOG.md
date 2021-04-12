# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5](https://github.com/nietaki/rexbug/tree/v1.0.5) - 2021-04-12

- Fix `no function clause matching in Inspect.Agebra.container_each/6` error happening in Elixir 1.11.0 [48](https://github.com/nietaki/rexbug/pull/48)
- Remove `&nbsp;` from Rexbug module docs [50](https://github.com/nietaki/rexbug/pull/48)

## [1.0.4](https://github.com/nietaki/rexbug/tree/v1.0.4) - 2020-02-20

### Changed

- Don't force consumers to pull in deps which are not vital [45](https://github.com/nietaki/rexbug/pull/45)

## [1.0.3](https://github.com/nietaki/rexbug/tree/v1.0.3) - 2019-09-08

### Changed

- Fix warnings when running on Elixir 1.8.x and Erlang 22 [35](https://github.com/nietaki/rexbug/pull/35) [37](https://github.com/nietaki/rexbug/pull/37)
- Fix the `print_msec` option [39](https://github.com/nietaki/rexbug/pull/39)
- Fix edge cases with `:send` and `:receive` [40](https://github.com/nietaki/rexbug/pull/40) [41](https://github.com/nietaki/rexbug/pull/41)
