class_name BoardState

#### static vars ####
var fen: String # Fen for the board state, this is source of truth
var num_squares: int # number of squares for board
var square_width: int # pixels (same as chess piece images)

#### computed vars (from fen) ####
var half_moves: int
var full_moves: int
var passant: String # "-" if no en passants
var to_move: String
var castling: String # "-" if no castling
var board: Array # 2d array containing piece or null for all squares from fen

#### defaults ####
var default_fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0"

# setup initial values
func setup(
	_fen: String = default_fen, 
	_num_squares: int = 64,
  _square_width: int = 64):
  fen = _fen
  num_squares = _num_squares
  _parse_fen_set_vars()



## use FEN to set class variables, sets:
# half_moves: int
# full_moves: int
# passant: str
# to_move: int
# castling: str
# board: Array
func _parse_fen_set_vars():
	var parts = fen.split(" ")
	var to_move = parts[1]
	var i = 0
	var _board = [[]]
	for ch in parts[0]:
		match ch:
			"/": # Next rank
				_board.append([])
				i += 1
				pass
			"1", "2", "3", "4", "5", "6", "7", "8":
				# warning-ignore:unused_variable
				for unused in range(int(ch)):
					_board[i].append(null)
			_:
				# set_piece(ch, i, castling)
				var p = Piece.new()
				p.key = ch
				_board[i].append(p)
  board = _board
	passant = parts[3]
	castling = parts[2]
	# Set halfmoves value
	half_moves = parts[4].to_int()
	full_moves = parts[5].to_int()

