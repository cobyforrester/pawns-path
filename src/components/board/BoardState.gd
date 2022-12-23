class_name BoardState

#### static vars ####
export(Color) var white # Square color
export(Color) var grey # Square color
export(Color) var mod_color # For highlighting squares
var num_squares: int # number of squares for board
var square_width: int # pixels (same as chess piece images)

#### computed vars (from fen) ####
var half_moves: int
var full_moves: int
var passant: String # "-" if no en passants
var to_move: String
var castling: String # "-" if no castling
var grid: Array # 2d array containing piece or null for all squares from fen

### dynamic vars ###
var fen: String # Fen for the board state, this is source of truth
var highlighed_tiles = []

#### defaults ####
var default_fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0"

# setup initial values
func setup(
	_fen: String = default_fen, 
	_num_squares: int = 64,
  _square_width: int = 64):
  fen = _fen
  num_squares = _num_squares
  square_width = _square_width
  _parse_fen_set_state()
  _state_to_fen()


## use FEN to set class variables, sets:
# half_moves: int
# full_moves: int
# passant: str
# to_move: int
# castling: str
# grid: Array
func _parse_fen_set_state():
	var parts = fen.split(" ")
	var to_move = parts[1]
	var i = 0
	var _grid = [[]]
	for ch in parts[0]:
		match ch:
			"/": # Next rank
				_grid.append([])
				i += 1
				pass
			"1", "2", "3", "4", "5", "6", "7", "8":
				# warning-ignore:unused_variable
				for unused in range(int(ch)):
					_grid[i].append(null)
			_:
				# set_piece(ch, i, castling)
				var p = Piece.new()
				p.key = ch
				_grid[i].append(p)
  grid = _grid
	passant = parts[3]
	castling = parts[2]
	# Set halfmoves value
	half_moves = parts[4].to_int()
	full_moves = parts[5].to_int()

func _state_to_fen():
  var _fen = []

  # convert grid to str
  var grid_str = ""
  var null_count = 0
  for row in grid:
    null_count = 0
    for col in row:
      if col == null:
        null_count += 1
      else:
        if null_count != 0:
          grid_str += null_count
          null_count = 0
        grid_str += col.key
    if null_count != 0:
      grid_str += null_count
    grid_str += "/"

	print(grid_str)

