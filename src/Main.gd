extends Control

onready var engine = $Engine
onready var fd = $c/FileDialog
onready var promote = $c/Promote
onready var board = $VBox/Board

var selected_piece : Piece
var show_suggested_move = true
var white_next = true
var state = IDLE

# states
enum { IDLE, CONNECTING, STARTING, PLAYER_TURN, ENGINE_TURN, PLAYER_WIN, ENGINE_WIN }
# events
enum { CONNECT, NEW_GAME, DONE, ERROR, MOVE }

func _ready():
	board.connect("clicked", self, "piece_clicked")
	board.connect("unclicked", self, "piece_unclicked")
	board.connect("moved", self, "mouse_moved")
	board.get_node("Grid").connect("mouse_entered", self, "mouse_entered")
	board.connect("taken", self, "stow_taken_piece")


func handle_state(event, msg = ""):
	match state:
		IDLE:
			pass
			print(event, msg)




# This is called after release of the mouse button and when the mouse
# has crossed the Grid border so as to release any selected piece
func mouse_entered():
	pass


func piece_clicked(piece):
	piece.obj.z_index = 1
	selected_piece = piece


func piece_unclicked(piece):

	return_piece(piece)
	pass



func mouse_moved(pos):
	if selected_piece != null:
		selected_piece.obj.position = pos - Vector2(board.square_width, board.square_width) / 2.0

func return_piece(piece: Piece):
	if piece != null:
		piece.obj.position = Vector2(0, 0)
		piece.obj.z_index = 0
		selected_piece = null
