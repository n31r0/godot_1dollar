extends Control
#extends Node2D

## todo- turn this into an addon for godot, so it is easier to reuse in other projects
signal shapeDetected 

var pressed = false
var guestures = preload("recognizer.gd").new()
var draw = []
var recognize = false
var position = Vector2()
var scriptPath = self.get_script().get_path().get_base_dir()
onready var gestureJsonFilePath = scriptPath+"recordedGestures.json"
var maxInk = 1
onready var curInk = maxInk

var mouseCursorIconPath = scriptPath+"pencil.png"
export var recording = true
export var particleEffect = true

var particleNode = null 
func _ready():
	set_process(true)
	set_process_input(true)
	if particleEffect:
		particleNode = Particles2D.new()
		particleNode.set_name("drawParticle")
		particleNode.set_pos(Vector2(50,50))
		particleNode.set_initial_velocity(Vector2(0,0))
		particleNode.set_use_local_space(false)
		particleNode.set_amount(64)
		particleNode.set_lifetime(1)
		particleNode.set_param(particleNode.PARAM_LINEAR_VELOCITY,0)
		particleNode.set_param(particleNode.PARAM_GRAVITY_STRENGTH,0)
		particleNode.set_param(particleNode.PARAM_INITIAL_SIZE,20)
		position = particleNode.get_pos()
		add_child(particleNode)
	connect("mouse_enter",self,"_on_mouse_enter")
	connect("mouse_exit",self,"_on_mouse_exit")
	loadSavedGesturesFromJson(gestureJsonFilePath)

func _process(delta): pass

func _input(event):
	if canDraw:
		if (event.is_action_pressed("m_btn")):
			draw = []
			pressed = event.pressed
			position.x = get_viewport().get_mouse_pos().x
			position.y = get_viewport().get_mouse_pos().y
			if particleEffect:
				particleNode.set_emitting(true)
				particleNode.set_pos(position)

		if (event.is_action_released("m_btn")): ## detect the gesture from memory
			pressed = event.pressed
			if (draw.size() > 4):
				recogniseDrawnGesture()
			curInk = maxInk

		if (event.type == InputEvent.MOUSE_MOTION && pressed) and curInk > 0:
			position.x = get_viewport().get_mouse_pos().x
			position.y = get_viewport().get_mouse_pos().y
			draw.append(position)
			if particleEffect:
				particleNode.set_pos(position)
			if draw.size() % 2:update() ## dont update so often
		if curInk <= 0:
			recogniseDrawnGesture()

func recogniseDrawnGesture():
	get_node("gui/status").set_text(str(guestures.recognize(draw)," ink left:",curInk))
	get_node("gui/addGuester/draw").set_text(str("draw: ",draw.size()," uni: ",guestures.Unistrokes.size()))
	if particleEffect: ## particle effect is optional
		particleNode.set_pos(position)
		particleNode.set_emitting(false)
	emit_signal("shapeDetected",guestures.recognize(draw),curInk)
	drawColShapePolygon(draw)
	curInk = maxInk
	update()
	if not recording : draw = []

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

func _on_mouse_enter():
	canDraw = true
	Input.set_custom_mouse_cursor(load(mouseCursorIconPath),Vector2(30,20))
	print("inside drawzone")
func _on_mouse_exit():
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
export var maxDrawnColShapes = 3
func drawColShapePolygon(vector2arr):
	if curInk > 0 and createColisions:
		vector2arr = simplifyArr(vector2arr,6)
		print ("col shape points:",vector2arr.size())
		var colShapePol = CollisionPolygon2D.new()
		colShapePol.set_polygon(vector2arr)
		colShapePol.add_to_group(str("drawnShape:",guestures.recognize(draw))) ##will be useful later on for colisions
		colShapePol.add_to_group("drawnShapes") ## use to keep track of all
		add_child(colShapePol)
	### limit how many maximum drawn shapes can exist ### you can destroy them on collision elsewhere
	if maxDrawnColShapes > 0:##if set to 0, it is disabled
		if get_tree().get_nodes_in_group("drawnShapes").size() > maxDrawnColShapes:
			get_tree().get_nodes_in_group("drawnShapes")[0].queue_free()## remove the oldest

########## helper functions ###############
func simplifyArr(inputArray,simplifyAmount): ##reduce the number of items in an array by taking out the inbetween ones
	for repeat in range(simplifyAmount):
		var itemInd = 0
		for item in inputArray:
			if itemInd % 2:
				inputArray.remove(itemInd)
			itemInd+=1
	return inputArray







