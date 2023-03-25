SHELL := /bin/bash

export TIMESTAMP=$(shell date +"%s")
export pwd=$(shell pwd)

.PHONY: all
all: install check

.PHONY: install
install:
	/usr/local/bin/rtx install
	mix deps.get

.PHONY: check
check:
	mix test
	mix format --check-formatted
	mix coveralls
	mix credo || exit 0
	mix docs

.PHONY: clean
clean:
	mix clean
	mix deps.clean --all
