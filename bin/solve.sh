#!/bin/bash
DIRNAME="$(dirname "${BASH_SOURCE[0]}")"

# Add bindings for SUDOKU host & port
source "$DIRNAME/info.sh"

FILE="$1"
# If the file isn't supplied, default to empty board:
if [[ -z "$FILE" ]] ; then
  FILE="$DIRNAME/../data/empty_board.json"
fi

BOARD_JSON=$(cat "$FILE")

curl -X POST -d "board=$BOARD_JSON" "$SUDOKU_HOST:$SUDOKU_PORT/solve"
