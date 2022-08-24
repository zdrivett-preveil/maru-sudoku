defmodule MaruSudoku.Solver do
  # A basic implementation of a Sudoku solver, using backtracking.
  # - https://en.wikipedia.org/wiki/Sudoku
  # - https://en.wikipedia.org/wiki/Backtracking

  # For simplicity, the code here is specific for 9x9 Sudoku boards.
  @board_size 9

  # The remaining constants could be derived from @board_size, but it
  #  seemed that just `3` reads better than `trunc(:math.sqrt(@board_size))`.
  @board_index_range 0..8
  @board_index_list Enum.to_list(0..8)

  @cell_value_range 0..9
  @cell_set_nonempty MapSet.new(1..9)

  @cell_count 81
  @box_size 3

  # Board is expected to be a map of maps,
  #  with the outer indices being row, and
  #  the inner indices being columns.
  def is_valid(board) do
    has_indices? = fn(m) -> Map.keys(m) |> Enum.sort == @board_index_list end

    valid_cell?  = fn(i) -> i in @cell_value_range end
    valid_cells? = fn(m) -> Enum.all?(Map.values(m), valid_cell?) end

    is_map(board)
    and has_indices?.(board)
    and Map.values(board) |> Enum.all?(&is_map/1)
    and Map.values(board) |> Enum.all?(has_indices?)
    and Map.values(board) |> Enum.all?(valid_cells?)
    # TODO see if with can reduce repetition of Map.values(board) above.
  end

  # Provide a means of accessing the board in terms of row, column, or box.
  # (Given a board and that index, return a list of squares.)
  # These helpers return a partially-applied function for a given board,
  #  allowing later functions to simply map them over a range of indices.

  # f(board) -> f(row_idx) -> row
  def partial_get_row(mm_board) do
    fn row ->
      Enum.map(@board_index_range,
        fn col -> mm_board[row][col] end
      )
    end
  end

  # f(board) -> f(col_idx) -> col
  def partial_get_column(mm_board) do
    fn col ->
      Enum.map(@board_index_range,
        fn row -> mm_board[row][col] end
      )
    end
  end

  # To access a 3x3 box within a 9x9 board, give a box index:
  #   0 1 2
  #   3 4 5
  #   6 7 8
  # So box_idx of 3 yields: mm_board[3..5][0..2]
  def partial_get_box(mm_board) do
    fn box_idx ->
      row_start = div(box_idx, @box_size) * @box_size
      col_start = rem(box_idx, @box_size) * @box_size
      row_range = row_start..(row_start + @box_size - 1)
      col_range = col_start..(col_start + @box_size - 1)
      for row_idx <- row_range,
          col_idx <- col_range,
      do: mm_board[row_idx][col_idx]
    end
  end

  # If the board isn't a map of maps, but a list of lists,
  #  we have conversion functions from one format to the other.
  # (The solving functions assume the map of maps, because that
  #  should perform better for random access and updates, but
  #  the list of lists is easier to read as a person.)

  # List of lists -> map of maps, for Sudoku representation.
  def ll_to_mm(ll_board) do
    index_it = fn(l) -> Enum.zip(@board_index_range, l) end
    make_map = fn(l) -> Enum.into(l, %{}) end

    ll_board
    |> Enum.map(index_it)
    |> Enum.map(make_map)
    |> index_it.()
    |> make_map.()
  end

  # Map of maps -> list of lists, for Sudoku representation.
  def mm_to_ll(mm_board) do
    get_row = partial_get_row(mm_board)
    Enum.map(@board_index_range, get_row)
  end

  # Backtracking requires early termination checks.
  # If a Sudoku puzzle has the same nonempty number appear more than once
  #  within a row, column, or box, then it has a conflict. (Zero is empty.)
  # When we have a conflict, it doesn't matter how many more numbers are added,
  #  the puzzle will remain in conflict and unsolved.

  def has_nonzero_duplicates?(list) do
    rf = fn
      0, acc -> {:cont, acc} # ignore 0s
      n, acc -> if n in acc, do: {:halt, 0}, else: {:cont, [n | acc]}
    end
    # NOTE: realistically, we could use -- here, since lists are 9 max.
    # Also, the 'if n in acc` check, that's O(n) for a list, no?
    # So a MapSet there could get that to O(log(n)), but again, 9 elements.

    list
    |> Enum.reduce_while([], rf)
    |> is_integer()
  end

  def has_partial_conflict?(board, pf) do
    f = pf.(board)

    @board_index_range
    |> Enum.map(f)
    |> Enum.any?(&has_nonzero_duplicates?/1)
  end

  def has_conflict?(board) do
    has_partial_conflict?(board, &partial_get_column/1)
    or has_partial_conflict?(board, &partial_get_row/1)
    or has_partial_conflict?(board, &partial_get_box/1)
  end

  defp is_solved(board) do
    get_row = partial_get_row(board)
    list_matches = fn l -> MapSet.new(l) == @cell_set_nonempty end

    @board_index_range
    |> Enum.map(get_row)
    |> Enum.all?(list_matches)
  end

  def status(board) do
    cond do
      has_conflict?(board) -> :conflict
      is_solved(board) -> :solved
      true -> :incomplete
    end
  end
  # TODO: consider returning {status, board} for nicer pattern matching.

  defp cell_num_to_row_column(cell_num) do
    [div(cell_num, @board_size), rem(cell_num, @board_size)]
  end

  defp next_empty(_, cell_num) when (cell_num >= @cell_count), do: :oob
  defp next_empty(board, cell_num) do
    indices = cell_num_to_row_column(cell_num)
    if (get_in(board, indices) == 0) do
      {cell_num, indices} # Return both to avoid repeated work with cell_num
    else
      next_empty(board, cell_num + 1)
    end
  end

  defp r_solve_game(_, _, guess) when (guess > @board_size), do: :conflict
  defp r_solve_game(board, cell_num, guess) do
    case next_empty(board, cell_num) do
      :oob -> :conflict # square must be on the board
      {cell_num, indices} ->
        board_next = put_in(board, indices, guess) # Place a guess
        case status(board_next) do
          :solved -> board_next
          :conflict -> r_solve_game(board, cell_num, guess + 1) # next guess
          :incomplete ->
            case r_solve_game(board_next, cell_num + 1, 1) do   # next cell
              :conflict -> r_solve_game(board, cell_num, guess + 1)
              solution -> solution
            end
        end
    end
  end
    
  # TODO: guard with is_valid
  # (there's no sense running this body with garbage)
  def solve_game(board) do
    case status(board) do
      :conflict -> :conflict
      :solved -> board
      :incomplete -> r_solve_game(board, 0, 1)
    end
  end
end
