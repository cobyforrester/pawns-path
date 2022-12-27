extends Control

class_name Board

signal clicked
signal unclicked
signal moved
signal halfmove
signal fullmove

export var square_width = 64 # pixels (same as chess piece images)
export(Color) var white # Square color
export(Color) var grey # Square color
export(Color) var mod_color # For highlighting squares

enum { SIDE, UNDER }

var grid: Array # Map of what pieces are placed on the board
var default_fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0"
var r_count = 0 # Rook counter
var R_count = 0 # Rook counter
var halfmoves = 0 # Used with fifty-move rule. Reset after pawn move or piece capture
var fullmoves = 0 # Incremented after Black's move
var passant_pawn: Piece
var cleared = true
var highlighed_tiles = []
var board_state: BoardState

func _ready():
	# grid will map the pieces in the game
	board_state = BoardState.new()
	board_state.setup()
	grid.resize(board_state.num_squares)
	draw_tiles()
	setup_pieces()



func setup_pieces(_fen = default_fen):
	var i = 0
	for row in board_state.grid:
		for piece in row:
			if piece != null:
				set_piece(piece, i)
			i += 1 


func set_piece(p: Piece, i: int):
	p.pos = Vector2(i % 8, int(i / 8.0)) # godot hack
	p.obj = Pieces.get_piece(p.key, p.side)
	grid[i] = p
	print("========================")
	print(grid)
	print("========================")
	$Grid.get_child(i).add_child(p.obj)
	# Check castling rights


func set_halfmoves(n):
	halfmoves = n
	emit_signal("halfmove", n)


func set_fullmoves(n):
	fullmoves = n
	emit_signal("fullmove", n)


func draw_tiles():
	var white_square = ColorRect.new()
	white_square.color = white
	white_square.mouse_filter = Control.MOUSE_FILTER_PASS
	white_square.rect_min_size = Vector2(square_width, square_width)
	var grey_square = white_square.duplicate()
	grey_square.color = grey
	# Add squares to grid
	var odd = true
	for y in 8:
		odd = !odd
		for x in 8:
			odd = !odd
			if odd:
				add_square(white_square.duplicate(), x, y)
			else:
				add_square(grey_square.duplicate(), x, y)


func add_square(s: ColorRect, x: int, y: int):
	s.connect("gui_input", self, "square_event", [x, y])
	if x == 0:
		add_label(s, SIDE, String(8 - y))
	if y == 7:
		add_label(s, UNDER, char(97 + x))
	$Grid.add_child(s)


func add_label(node, pos, chr):
	var l = Label.new()
	l.add_to_group("labels")
	l.text = chr
	if pos == SIDE:
		l.rect_position = Vector2(-square_width / 4.0, square_width / 2.3)
	else:
		l.rect_position = Vector2(square_width / 2.3, square_width * 1.1)
	node.add_child(l)


func hide_labels(show = false):
	for label in get_tree().get_nodes_in_group("labels"):
		label.visible = show


func square_event(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()
		print("Clicked at: ", [x, y])
		var p = get_piece_in_grid(x, y)
		if p != null:
			if event.pressed:
				emit_signal("clicked", p)
			else:
				emit_signal("unclicked", p)
	# Mouse position is relative to the square
	if event is InputEventMouseMotion:
		emit_signal("moved", event.position)


func get_grid_index(x: int, y: int):
	return x + 8 * y


func get_piece_in_grid(x: int, y: int):
	var p = grid[get_grid_index(x, y)]
	return p


func move_piece(p: Piece, engine_turn: bool):
	var pos = get_grid_index(p.pos.x, p.pos.y)
	if engine_turn:
		highlighed_tiles.append(pos)
	grid[pos] = null
	pos = get_grid_index(p.new_pos.x, p.new_pos.y)
	if engine_turn:
		highlighed_tiles.append(pos)
	grid[pos] = p
	p.pos = p.new_pos
	# Re-parent piece on board
	p.obj.get_parent().remove_child(p.obj)
	p.obj.position = Vector2(0, 0)
	$Grid.get_child(p.pos.x + 8 * p.pos.y).add_child(p.obj)
	if p != passant_pawn:
		passant_pawn = null
	p.tagged = false # Prevent castling after move
	if p.key == "P":
		set_halfmoves(0)
	else:
		set_halfmoves(halfmoves + 1)
	if p.side == "B":
		set_fullmoves(fullmoves + 1)
	if engine_turn:
		$HighlightTimer.start()
		highlight_square(highlighed_tiles[0])
	else:
		highlighed_tiles = []
	cleared = false


func highlight_square(n: int, apply = true):
	assert(n >= 0)
	assert(n < board_state.num_squares)
	var sqr: ColorRect = $Grid.get_child(n)
	if apply:
		sqr.color = mod_color
	else:
		if square_is_white(n):
			sqr.color = white
		else:
			sqr.color = grey


func square_is_white(n: int):
# warning-ignore:integer_division
	return 0 == ((n / 8) + n) % 2


