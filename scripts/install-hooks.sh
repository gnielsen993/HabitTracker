#!/usr/bin/env bash
# Point git at the tracked .githooks/ directory.
#
# Hooks are PER-CLONE: core.hooksPath is local config and is not carried by
# git clone or git pull. Every clone on every machine must run this once, or
# the repo's rules go unenforced there with no signal that anything is off.
#
# Use a RELATIVE path. An absolute one silently dies if the repo ever moves --
# which is exactly what happened across this ecosystem when the repos went
# from ~/Desktop to ~/Developer, leaving hooks dead in several clones.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true
echo "core.hooksPath -> $(git config core.hooksPath)"
echo "Installed hooks: $(ls .githooks | tr '\n' ' ')"
