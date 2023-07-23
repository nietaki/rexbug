#!/usr/bin/env bash

set -euo pipefail

usage () {
    echo "$0"
    exit
}

err() {
    echo "ERROR: ${1:-}"
    exit 1
}

git remote -v | grep -q "git@github.com" || \
    err "git is readonly"
(git push && git status) | grep "Your branch is up to date with 'origin/master'." || \
    err "branch is not up to date with origin/master"
mix hex.user whoami | grep -q "nietaki" || \
    err "not logged in to hex as nietaki"

MIXEXS="$PWD/mix.exs"

[ -z "$MIXEXS" ] && usage

VSN=$(grep -oe "version: \".*\"" mix.exs | cut -d \" -f 2)

echo "will release 'v$VSN'"

mix rexbug.check
echo ""
mix hex.build
echo ""
echo ""

# if [[ -z $(git status -s) ]]
# then
#   echo "all changes committed, proceeding"
# else
#   err "There are uncommitted changes, commit first"
# fi

echo "will commit, tag and release"
echo "press <ENTER> to continue or <C-C> to cancel"

read

# git add "$MIXEXS"
git add .
git commit --allow-empty -m "v$VSN"
git tag -a -m "v$VSN" "v$VSN"
git push \
    && git push --tags \
    && mix hex.build \
    && mix hex.publish
