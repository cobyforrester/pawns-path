# BoardState contains logical state of board and pieces
# it also handles fen conversion
class_name BoardState

#### static vars ####
var num_squares: int # number of squares for board
var square_width: int # pixels (same as chess piece images)
var show_labels: bool

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
	_square_width: int = 64,
	_show_labels: bool = true):
	fen = _fen
	num_squares = _num_squares
	square_width = _square_width
	show_labels = _show_labels
	legal_moves = compute_legal_moves()
	_parse_fen_set_state()


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
				p.key = ch.to_lower()
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
				if col. side == "w":
					grid_str += col.key.to_upper()
				else:
					grid_str += col.key.to_lower()
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
	# translations for simplifying movement possibilities
	var r_translations = [[0,1], [0, -1], [1, 0], [-1, 0]]
	var b_translations = [[1,1], [-1, -1], [-1, 1], [1, -1]]
	var n_translations = [[2,1], [2, -1], [-2, 1], [-2, -1],[1,2], [1, -2], [-1, 2], [-1, -2]]
	var q_and_k_translations = r_translations + b_translations
	for i in grid.size():
		for j in grid[i].size():
			var notation = coordinates_to_notation(i, j, grid[i].size())
			if grid[i][j] != null:
				match grid[i][j].key.to_lower():
					"p": # pawn
						_legal_moves[notation] = _pawn_moves(i, j)
						pass
					"r": # rook
						_legal_moves[notation] = _infinite_direction_translations(i, j, r_translations)
						pass
					"b": # bishop
						_legal_moves[notation] = _infinite_direction_translations(i, j, b_translations)
						pass
					"q": # queen
						_legal_moves[notation] = _infinite_direction_translations(i, j, q_and_k_translations)
						pass
					"n": # knight
						_legal_moves[notation] = _single_point_translation(i, j, n_translations)
						pass
					"k": # king
						_legal_moves[notation] = _single_point_translation(i, j, q_and_k_translations)
						pass
	return _legal_moves

# calculate legal pawn moves for pawn
# don't need to account for it going out
# of bounds since it becomes another piece
# before then
func _pawn_moves(y, x):
	var pawn = grid[y][x]
	var direction = 1 if pawn.side.to_lower() == "b" else -1
	var possible_moves = []
	# move forward one space
	if grid[y + direction][x] == null:
		possible_moves.append(coordinates_to_notation(y + direction, x))
		# move forward two spaces
		if (grid[y + direction * 2][x] == null 
			&& ((pawn.side == "b" && y == 1) 
					|| (pawn.side == "w" && y == grid[y].size() - 2))): # check if not moved
			possible_moves.append(coordinates_to_notation(y + direction * 2, x))
	# move right one (white perspective)
	if (grid[y + direction].size() > x + 1 
			&& grid[y + direction][x + 1] != null 
			&& grid[y + direction][x + 1].side != pawn.side):
		possible_moves.append(coordinates_to_notation(y + direction, x+1))
	# move left one (white perspective)
	if (x - 1 >= 0 && grid[y + direction][x - 1] != null 
			&& grid[y + direction][x - 1].side != pawn.side):
		possible_moves.append(coordinates_to_notation(y + direction, x-1))
	return possible_moves

# check all directions piece can move, am I stupid or does this work well?
# translations is array of format [y, x] but actually for now never matters
# it takes an array of numbers to transform the x and y values
# then checks common conditions all pieces that move
# infinitely in one direction need to account for:
# am I on the board, is there a piece here, etc.
# this greatly reduces the code for bishops, rooks, and queens
func _infinite_direction_translations(y, x, translations: Array):
	var piece = grid[y][x]
	var side = piece.side
	var possible_moves = []
	var height = grid.size() 
	var width = grid[y].size() 
	# check all directions piece can move, am I stupid or does this work well?
	var y_tr: int
	var x_tr: int
	for translation in translations:
		y_tr = y + translation[0]
		x_tr = x + translation[1]
		while(x_tr < height && x_tr >= 0 && y_tr < width && y_tr > 0):
			if grid[y_tr][x_tr] != null:
				# if we hit a piece, add and break if opposite colors, otherwise just break
				if grid[y_tr][x_tr].side != side:
					possible_moves.append(coordinates_to_notation(y_tr, x_tr))
				break
			else:
				possible_moves.append(coordinates_to_notation(y_tr, x_tr))
			y_tr += translation[0]
			x_tr += translation[1]
	return possible_moves

# translations is array of format [y, x] but actually for now never matters
func _single_point_translation(y, x, translations: Array):
	var piece = grid[y][x]
	var side = piece.side
	var possible_moves = []
	var height = grid.size()
	var width = grid[y].size() 
	# check all directions piece can move, am I stupid or does this work well?
	var y_tr: int
	var x_tr: int
	for translation in translations:
		y_tr = y + translation[0]
		x_tr = x + translation[1]
		if x_tr < height && x_tr >= 0 && y_tr < width && y_tr > 0:
			if grid[y_tr][x_tr] != null:
				if grid[y_tr][x_tr].side != side:
					possible_moves.append(coordinates_to_notation(y_tr, x_tr))
			else:
				possible_moves.append(coordinates_to_notation(y_tr, x_tr))
	return possible_moves

# returns chess format, for example: e4
# coordinates is array with two elements, one for width one for height
func coordinates_to_notation(y, x, height = 8):
	var letter = char(97 + x)
	var num = height - y
	return str(letter) + str(num)

# turns x, y coordinates to i coordinates
# to translate my personal grid to what
# Grid from godot expects
func x_y_to_i(x, y, _height = 8):
	return _height * y + x

# get piece from the grid
func get_piece(x: int, y: int):
	return grid[y][x]