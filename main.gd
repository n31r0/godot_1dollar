extends Node

var pressed = false
var guestures = preload("recognizer.gd").new()
var draw = []
var recognize = false
var position = Vector2()

func _ready():
	set_process(true)
	set_process_input(true)
	position = get_node("gui/cube").get_pos()
	
func _process(delta):
	pass

func _input(event):
	if (event.is_action_pressed("m_btn")):
		pressed = event.pressed
		draw = []
		get_node("gui/cube").set_emitting(true)
		position.x = get_viewport().get_mouse_pos().x
		position.y = get_viewport().get_mouse_pos().y
	if (event.is_action_released("m_btn")):
		pressed = event.pressed
		if (draw.size() > 10):
			get_node("gui/status").set_text(str(guestures.recognize(draw)))
			get_node("gui/addGuester/draw").set_text(str("draw: ",draw.size()," uni: ",guestures.Unistrokes.size()))
		get_node("gui/cube").set_pos(position)
		get_node("gui/cube").set_emitting(false)
	
	if (event.type == InputEvent.MOUSE_MOTION && pressed):
		position.x = get_viewport().get_mouse_pos().x
		position.y = get_viewport().get_mouse_pos().y
		draw.append(position)
		get_node("gui/cube").set_pos(position)


func _on_addGuester_pressed():
	if (draw.size() > 10):
		var new_guester = preload("unistroke.gd").new(get_node("gui/addGuester/guester_name").get_text(), draw)
		guestures.Unistrokes.append(new_guester)
		get_node("gui/addGuester/draw").set_text(str("draw: ",draw.size()," uni: ",guestures.Unistrokes.size()))
		draw = []
