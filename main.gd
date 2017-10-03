extends Node2D

## todo- turn this into an addon for godot, so it is easier to reuse in other projects

var pressed = false
var guestures = preload("recognizer.gd").new()
var draw = []
var recognize = false
var position = Vector2()
var gestureJsonFilePath = "res://recordedGestures.json"
var maxInk = 1
onready var curInk = maxInk
var mouseCursorIconPath = "res://pencil.png"

func _ready():
	set_process(true)
	set_process_input(true)
	position = get_node("gui/cube").get_pos()
	loadSavedGesturesFromJson(gestureJsonFilePath)

func _process(delta): pass
#	if curInk>0:
#		curInk -= 0.001
#		update()

func _input(event):
	if canDraw:
		if (event.is_action_pressed("m_btn")):
			draw = []
			pressed = event.pressed
			get_node("gui/cube").set_emitting(true)
			position.x = get_viewport().get_mouse_pos().x
			position.y = get_viewport().get_mouse_pos().y
			get_node("gui/cube").set_pos(position)

		if (event.is_action_released("m_btn")): ## detect the gesture from memory
			pressed = event.pressed
			if (draw.size() > 4):
				get_node("gui/status").set_text(str(guestures.recognize(draw)," ink left:",curInk))
				get_node("gui/addGuester/draw").set_text(str("draw: ",draw.size()," uni: ",guestures.Unistrokes.size()))
				get_node("gui/cube").set_pos(position)
				get_node("gui/cube").set_emitting(false)
				drawColShapePolygon(draw)
				curInk = maxInk
				update()
			
		if (event.type == InputEvent.MOUSE_MOTION && pressed):
			position.x = get_viewport().get_mouse_pos().x
			position.y = get_viewport().get_mouse_pos().y
			draw.append(position)
			get_node("gui/cube").set_pos(position)
			update()

var savedGestures = []
var data = {}
func _on_addGuester_pressed():
	if (draw.size() > 4):
		var new_guester = preload("unistroke.gd").new(get_node("gui/addGuester/guester_name").get_text(), draw)
		guestures.Unistrokes.append(new_guester)
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


## can we draw or not - the mouse needs to be inside the area
var canDraw = false
func _on_draw_zone_mouse_enter():
	canDraw = true
	Input.set_custom_mouse_cursor(load(mouseCursorIconPath),Vector2(30,20))

func _on_draw_zone_mouse_exit():
	canDraw = false
	Input.set_custom_mouse_cursor(null)

########### draw a shape ################
export var lineThickness = 2
export var lineColor = Color(255, 0, 0,1)
export var inkHealthBarWidth = 100

func _draw():## draw a line and an ink health bar
	var lineIndex = 0
	for line in draw:
		if lineIndex > 0 and curInk>0: ##draw freehand line
			curInk -= 0.001 ## run out of ink when drawing
			draw_line(draw[lineIndex-1], draw[lineIndex], Color(lineColor.r,lineColor.g,lineColor.b,curInk), lineThickness)
		lineIndex +=1
	if curInk > 0 and inkHealthBarWidth > 0 :## indicate how much ink is left
		draw_rect(Rect2(10,10,curInk*inkHealthBarWidth,20),lineColor)

### draw a colision shape from the array ###
export var createColisions = true
export var simplifyColShape = 6
export var maxDrawnColShapes = 3
func drawColShapePolygon(vector2arr):
	if curInk > 0 and createColisions:
		for repeat in range(simplifyColShape):
			vector2arr = simplifyArr(vector2arr)
		print ("col shape points:",vector2arr.size())
		var colShapePol = CollisionPolygon2D.new()
		colShapePol.set_polygon(vector2arr)
		colShapePol.add_to_group(str(guestures.recognize(draw))) ##will be useful later on for colisions
		colShapePol.add_to_group("drawnShapes") ## use to keep track of all
		add_child(colShapePol)
	### limit how many maximum drawn shapes can exist ### you can destroy them on collision elsewhere
	if maxDrawnColShapes > 0:
		if get_tree().get_nodes_in_group("drawnShapes").size() > maxDrawnColShapes:
			get_tree().get_nodes_in_group("drawnShapes")[0].queue_free()## remove the oldest

########## helper functions ###############
func simplifyArr(inputArray):
	var itemInd = 0
	for item in inputArray:
		if itemInd % 2:
			inputArray.remove(itemInd)
		itemInd+=1
	return inputArray