defmodule MaruSudoku.Router.Homepage do
  use Maru.Router
  alias MaruSudoku.Solver, as: Solver

  # TODO: delete or replace this endpoint.
  get do
    json(conn, "Greetings from a Maru + Elixir Sudoku solver")
  end

  # Take post parameters
  params do
    requires :board, type: Json
  end
  post :solve do
    board = params[:board]
    board_mm = Solver.ll_to_mm(board)
    # TODO see if there is a more OTP-like way to call the solver
    case MaruSudoku.Solver.solve_game(board_mm) do
      :conflict -> json(conn, ["Board is unsolvable", board])
      solution -> json(conn, %{:solution => Solver.mm_to_ll(solution)})
    end
  end

end

defmodule MaruSudoku.API do
  use Maru.Router

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json, :multipart]

  mount MaruSudoku.Router.Homepage

  rescue_from :all, as: e do
    e |> inspect(pretty: true) |> IO.puts()
    conn
    |> put_status(500)
    |> text("Server Error")
  end
end
