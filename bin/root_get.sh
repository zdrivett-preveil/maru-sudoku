#!/bin/bash
DIRNAME="$(dirname "${BASH_SOURCE[0]}")"

# Add bindings for SUDOKU host & port
source "$DIRNAME/info.sh"
curl "$SUDOKU_HOST:$SUDOKU_PORT"
