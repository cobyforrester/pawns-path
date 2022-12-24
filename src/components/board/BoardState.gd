# BoardState contains logical state of board and pieces
# it also handles fen conversion
class_name BoardState

#### static vars ####
var num_squares: int # number of squares for board
var square_width: int # pixels (same as chess piece images)

#### computed vars (from fen) ####
var half_moves: int
var full_moves: int
var passant: String # "-" if no en passants
var to_move: String
var castling: String # "-" if no castling
var grid: Array # 2d array containing piece or null for all squares from fen
var legal_moves: Dictionary

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
	compute_legal_moves()


## use FEN to set class variables, sets:
# half_moves: int
# full_moves: int
# passant: str
# to_move: int
# castling: str
# grid: Array
func _parse_fen_set_state():
	var parts = fen.split(" ")
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
				if ch.to_upper() == ch:
					p.side = "w"
				else:
					p.side = "b"
				p.key = ch
				_grid[i].append(p)
	grid = _grid
	to_move = parts[1]
	castling = parts[2]
	passant = parts[3]
	# Set halfmoves value
	half_moves = parts[4].to_int()
	full_moves = parts[5].to_int()

# state to fen, returns fen
func _state_to_fen():
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
					grid_str += str(null_count)
					null_count = 0
				grid_str += col.key
		if null_count != 0:
			grid_str += str(null_count)
		grid_str += "/"

	grid_str = grid_str.substr(0, grid_str.length() - 1) # remove / at end
	# fen string
	var _fen = ""
	_fen += grid_str
	_fen += " " + to_move
	_fen += " " + castling
	_fen += " " + passant
	_fen += " " + str(half_moves)
	_fen += " " + str(full_moves)
	return _fen

# compute legal moves based off grid
func compute_legal_moves():
	var _legal_moves = {}
	# initialize dictionary of positions to moves list
	for i in grid.size():
		for j in grid[i].size():
			var notation = coordinates_to_notation(i, j, grid[i].size())
			if grid[i][j] != null:
				match grid[i][j].key.to_lower():
					"p": # Next rank
						_legal_moves[notation] = _pawn_moves(i, j)
						pass
					"f": # Next rank
						pass

# calculate legal pawn moves for pawn
# don't need to account for it going out
# of bounds since it becomes another piece
# before then
func _pawn_moves(y, x):
	var pawn = grid[y][x]
	var direction = 1 if pawn.side.to_lower() == "b" else -1
	var possible_moves = []
	# move forward
	if grid[y + direction][x] == null:
		possible_moves.append(coordinates_to_notation(y + direction, x))
		if grid[y + direction * 2][x] == null: # check if not moved
			possible_moves.append(coordinates_to_notation(y + direction * 2, x))
	# move right one (white perspective)
	if grid[y + direction].size() > x + 1 && grid[y + direction][x + 1] != null && grid[y + direction][x + 1].side != pawn.side:
		possible_moves.append(coordinates_to_notation(y + direction, x+1))
	# move left one (white perspective)
	if x - 1 >= 0 && grid[y + direction][x - 1] != null && grid[y + direction][x - 1].side != pawn.side:
		possible_moves.append(coordinates_to_notation(y + direction, x-1))
	print(possible_moves)


# returns chess format, for example: e4
# coordinates is array with two elements, one for width one for height
func coordinates_to_notation(y, x, height = 8):
	var letter = char(97 + x)
	var num = height - y
	return str(letter) + str(num)

