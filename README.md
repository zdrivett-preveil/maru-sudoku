# Maru Sudoku

A sample Elixir/Maru webservice, which just happens to also be a Sudoku solver.

## Usage

Start server in one terminal:
```sh
mix deps.get && mix clean && mix run --no-halt
```

Hit the server from another terminal:
```sh
bin/solve.sh
```

Which returns a solution for the default `data/empty_board.json`:
```json
{"solution":[[1,2,3,4,5,6,7,8,9],[4,5,6,7,8,9,1,2,3],[7,8,9,1,2,3,4,5,6],[2,1,4,3,6,5,8,9,7],[3,6,5,8,9,7,2,1,4],[8,9,7,2,1,4,3,6,5],[5,3,1,6,4,2,9,7,8],[6,4,2,9,7,8,5,3,1],[9,7,8,5,3,1,6,4,2]]}
```

Supply a different starting board:

```sh
bin/solve.sh data/board_0.json
```

```json
{"solution":[[7,3,9,5,1,2,6,4,8],[8,1,4,3,6,9,5,2,7],[6,2,5,8,4,7,3,1,9],[3,6,2,7,5,8,1,9,4],[1,5,8,9,3,4,7,6,2],[4,9,7,1,2,6,8,3,5],[5,7,6,4,9,1,2,8,3],[9,8,1,2,7,3,4,5,6],[2,4,3,6,8,5,9,7,1]]}
```
