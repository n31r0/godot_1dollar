extends Node

var pressed = false
var guestures = preload("recognizer.gd").new()
var draw = []
var recognize = false
var position = Vector2()
var gestureJsonFilePath = "res://recordedGestures.json"

func _ready():
	set_process(true)
	set_process_input(true)
	position = get_node("gui/cube").get_pos()
	
	yield(get_tree(), "idle_frame")
	loadSavedGesturesFromJson(gestureJsonFilePath)

func _process(delta):
	pass

func _input(event):
	if (event.is_action_pressed("m_btn")):
		draw = []
		pressed = event.pressed
		get_node("gui/cube").set_emitting(true)
		position.x = get_viewport().get_mouse_pos().x
		position.y = get_viewport().get_mouse_pos().y
		get_node("gui/cube").set_pos(position)
	if (event.is_action_released("m_btn")): ## detect the gesture from memory
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

var savedGestures = []
var data = {}
func _on_addGuester_pressed():
	if (draw.size() > 10):
		var new_guester = preload("unistroke.gd").new(get_node("gui/addGuester/guester_name").get_text(), draw)
		guestures.Unistrokes.append(new_guester) ## This is where it stores them!- todo add load/save to json
		## store to array that will be written to the json file
		savedGestures.append([get_node("gui/addGuester/guester_name").get_text(),var2str(draw)])
		print("we have ",savedGestures.size()," gestures so far")
		get_node("gui/addGuester/draw").set_text(str("draw: ",draw.size()," uni: ",guestures.Unistrokes.size()))
		draw = []

func _on_Button_pressed():
	saveGesturesToJsonFile()

func saveGesturesToJsonFile():
	data = {}
	var file = File.new()
	file.open(gestureJsonFilePath, File.WRITE)
	data["gestures"] = savedGestures
	file.store_line(data.to_json())
	file.close()
	print("saved ",savedGestures.size()," gestures")
#	print("saving ",data)

var loadedGestures = []
func loadSavedGesturesFromJson(path):
	print("loading gestures from:",path)
	var file = File.new()
	file.open(gestureJsonFilePath, File.READ)
	var rawString = file.get_as_text()
	if rawString.length() == 0:return #nothing loaded, thus skip
	data.parse_json(rawString)
	
	for gesture in data["gestures"]:
		var cleanedGesture = []
		for vectorval in str2var(gesture[1]):
			cleanedGesture.append(vectorval)
		var cleanedGestureData = []
		cleanedGestureData.append(str(gesture[0]))
		cleanedGestureData.append(cleanedGesture)
		print(str("loaded gesture ",gesture[0]),"-",cleanedGesture.size()," points")
		loadedGestures.append(cleanedGestureData)
		savedGestures.append(gesture)

	for load_guester in loadedGestures:
		var new_guester = preload("unistroke.gd").new(load_guester[0], load_guester[1])
		guestures.Unistrokes.append(new_guester)
	print ("Loaded ",loadedGestures.size()," gestures!")



