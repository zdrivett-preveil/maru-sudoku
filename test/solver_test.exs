defmodule MaruSudoku.SolverTest do
  use ExUnit.Case, async: false

  alias MaruSudoku.Solver
  doctest MaruSudoku.Solver

  # Some helpers for data:
  defp empty_row() do
    f = fn(col, acc) -> Map.put_new(acc, col, 0) end
    Enum.reduce(0..8, %{}, f)
  end

  defp empty_board() do
    f = fn({v, row}, acc) -> Map.put(acc, row, v) end

    List.duplicate(empty_row(), 9)
    |> Enum.with_index()
    |> Enum.reduce(%{}, f)
  end

  test "is_valid(board)" do
    eb = empty_board()
    assert(Solver.is_valid(eb))
    assert(!Solver.is_valid("this string isn't a nested map"))
    too_small = Map.delete(eb, 3)
    assert(!Solver.is_valid(too_small))
  end

  def box_of_things() do
    [Enum.to_list(11..19),
     Enum.to_list(21..29),
     Enum.to_list(31..39),
     Enum.to_list(41..49),
     Enum.to_list(51..59),
     Enum.to_list(61..69),
     Enum.to_list(71..79),
     Enum.to_list(81..89),
     Enum.to_list(91..99)]
  end

  test "partial_get_row(mm_board)" do
    box = box_of_things()
    get_row =
      box
      |> Solver.ll_to_mm()
      |> Solver.partial_get_row()
    row_0 = get_row.(0)
    assert(row_0 == [11, 12, 13, 14, 15, 16, 17, 18, 19])

    [_r0, _r1, _r2, _r3, r4 | rest] = box
    assert(get_row.(4) == r4)
  end

  def pp(x) do
    x |> inspect(pretty: true) |> IO.puts()
  end

  test "solve_game(board)" do
    # The empty board has many solutions, but this solver will always
    #  yield the first one it finds, which is as follows:
    expected_solution_ll =
      [[1, 2, 3, 4, 5, 6, 7, 8, 9],
       [4, 5, 6, 7, 8, 9, 1, 2, 3],
       [7, 8, 9, 1, 2, 3, 4, 5, 6],
       [2, 1, 4, 3, 6, 5, 8, 9, 7],
       [3, 6, 5, 8, 9, 7, 2, 1, 4],
       [8, 9, 7, 2, 1, 4, 3, 6, 5],
       [5, 3, 1, 6, 4, 2, 9, 7, 8],
       [6, 4, 2, 9, 7, 8, 5, 3, 1],
       [9, 7, 8, 5, 3, 1, 6, 4, 2]]
    actual_solution_ll =
    empty_board()
    |> Solver.solve_game()
    |> Solver.mm_to_ll()

    assert(actual_solution_ll == expected_solution_ll)

    sparse_board_ll = [ # Includes three 3's:
      [3, 0, 0, 0, 0, 0, 0, 0, 0], # [0, 0]
      [0, 0, 0, 0, 0, 0, 3, 0, 0], # [1, 6]
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 3, 0, 0, 0, 0, 0], # [4, 3]
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ]
    expected_solution_ll = [
      [3, 1, 2, 4, 5, 6, 7, 8, 9],
      [4, 5, 6, 7, 8, 9, 3, 1, 2],
      [7, 8, 9, 1, 2, 3, 4, 5, 6],
      [1, 2, 3, 5, 4, 7, 6, 9, 8],
      [5, 6, 4, 3, 9, 8, 1, 2, 7],
      [8, 9, 7, 2, 6, 1, 5, 3, 4],
      [2, 3, 1, 8, 7, 4, 9, 6, 5],
      [6, 4, 5, 9, 1, 2, 8, 7, 3],
      [9, 7, 8, 6, 3, 5, 2, 4, 1]
    ]

    assert(
      sparse_board_ll
      |> Solver.ll_to_mm()
      |> Solver.solve_game()
      |> Solver.mm_to_ll() == expected_solution_ll)
  end

  test "solve_game(board) -- sad path" do
    unsolvable_because_row_ll = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 5, 0, 0, 0, 0, 0, 5],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ]
    assert(
      unsolvable_because_row_ll
      |> Solver.ll_to_mm()
      |> Solver.solve_game() == :conflict
    )
    unsolvable_because_col_ll = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 9, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 9, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0]
    ]
    assert(
      unsolvable_because_col_ll
      |> Solver.ll_to_mm()
      |> Solver.solve_game() == :conflict
    )

    unsolvable_because_box_ll = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 1, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 1, 0]
    ]
    assert(
      unsolvable_because_box_ll
      |> Solver.ll_to_mm()
      |> Solver.solve_game() == :conflict
    )
  end
end
