#!/usr/bin/env bash
set -e

# this file is invoked by sublime and by ./export.sh

shrinko8 --count --minify \
    --const dev false \
    --minify-safe-only \
    --no-minify-lines \
    --no-minify-rename \
    --no-minify-spaces \
    --no-minify-comments \
    "$@"
