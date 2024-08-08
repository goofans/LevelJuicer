extends Node2D

		# NOTE #
	# There is no justification for how the code is written, I am sorry


		# - VARIABLES -
	# FILES
var save_file: FileAccess # Users save data
var game_path: String # Path to wog2.exe
var data: Dictionary # Level data
var file: FileAccess # File access
var pre_path: String
@onready var file_dialog: FileDialog = $Level_FILE
@onready var game_dialog: FileDialog = $Game_FILE


var item_xml: Dictionary # Item XML


	# ARRAYS - TODO - cache positions in ball UIDs for optimization?
var ball_uids: Dictionary = {} # Ball details for visualizing in the editor
@onready var items: Node2D = $Items # Node2D that contains all item sprites


	# VISUALS
var main_color: Color = Color.WHITE # Main color
var select_color: Color = Color("ffa596") # Selection color for modulating


	# MOUSE - TODO - add multi selection
var sel_goo: Dictionary # Selected goo
var held_goo: Dictionary # Currently held goo
var hovered_goo: Dictionary # Currently hovered goo

var holding_goo: bool = false # If holding goo
var hovering_goo: bool = false # If hovering over goo
var selected_goo: bool = false # If a goo ball is currently selected

var zoom: float = 60.0 # Camera zoom
var cur_dir: Vector2 = Vector2.ZERO # Cursor direction
@onready var camera: Camera2D = $Camera # Camera
var mouse_pos: Vector2 = Vector2.ZERO # Cursor position

var line_mode: bool = false # Is drawing lines


	# UI
@onready var goo_container: HBoxContainer = $Control_LAYER/Control/Ball_PANEL/Scroll_CONTAINER/H_Box_CONTAINER # Contains the goo spawn buttons
@onready var load_popup: PopupMenu = $Load_POPUP

@onready var menu: CanvasLayer = $Control_LAYER # Entirety of the menu
@onready var proj_name: Label = $Control_LAYER/Control/Top_Right_PANEL/Name_LABEL # Name of the level
@onready var detail_container: VBoxContainer = $Control_LAYER/Control/Info_PANEL/V_Box_CONTAINER


	# BALLS
var uid_increment: int = 100000 # Starting UID to increment for each ball


		# - FUNCTIONS -
	# MAIN
func _ready() -> void: # Defaults
	set_process(false)
	
	if (FileAccess.file_exists("user://user_data.dat")):
		save_file = FileAccess.open("user://user_data.dat", FileAccess.READ)
		game_path = save_file.get_as_text()
		save_file.close()

	if (!game_path):
		game_dialog.title = "Select World of Goo 2's Executable"
		
		if (OS.get_name() == "Windows"):
			game_dialog.add_filter("*.exe")
			
		if (OS.get_name() == "macOS"):
			game_dialog.add_filter("*.app")
			
		game_dialog.visible = true # So it isn't in the way in the editor
	
	else:
		file_dialog.set_current_dir(game_path + "res/levels")
		file_dialog.title = "Open a File"
		file_dialog.add_filter("*.wog2")
		file_dialog.visible = true

	remove_child(menu)


	# FILES
func _Game_Selected(path: String) -> void:
	game_path = path
	
	# The executable name is different depending if the game is on EGS or not
	if (OS.get_name() == "Windows"):
		game_path = game_path.replace("World of Goo 2.exe", "game/")
		game_path = game_path.replace("WorldOfGoo2.exe", "game/")
		
	if (OS.get_name() == "macOS"):
		game_path = game_path.replace("World of Goo 2.app", "World of Goo 2.app/Resources/game/")
		game_path = game_path.replace("WorldOfGoo2.app", "WorldOfGoo2.app/Resources/game/")
	
	# I gotta confirm if this is right for Linux
	if (OS.get_name() == "Linux"):
		game_path = game_path.replace("World of Goo 2", "game/")
		game_path = game_path.replace("WorldOfGoo2", "game/")
	
	if (!FileAccess.file_exists("user://save_data.dat")):
		save_file = FileAccess.open("user://save_data.dat", FileAccess.WRITE)
		save_file.store_string(game_path)
		save_file.close()


	game_dialog.visible = false
	file_dialog.set_current_dir(game_path + "res/levels")
	file_dialog.add_filter("*.wog2")
	file_dialog.visible = true
	

func _Level_Selected(path: String) -> void: # User selected a level
	pre_path = path # Save path for saving the file
	file = FileAccess.open(path, FileAccess.READ)
	data = JSON.parse_string(file.get_as_text()) # Get data from file
	file = null # Close file
	
	
		# BALLS
	for ball: Dictionary in data.balls: # Get balls
		if ball.uid > uid_increment: uid_increment = ball.uid + 1
			# More detailed ball for editor use
		ball_uids[ball.uid] = {
			ball_ref = ball, # Original ball
			color = Globals.ball_details[ball.typeEnum].color, # Editor color
			strands = [] # Connections
		}
		
		#if ball.uid == 10:
			#terrain.polygon.append(Vector2(ball.pos.x, -ball.pos.y) * zoom)
	
		# ITEMS
	var sprite: Sprite2D
	var item_data: Dictionary # Item name from .wog2
	var xml: XMLParser = XMLParser.new()
	xml.open(game_path + "res/items/images/_resources.xml")
	
	for item: Dictionary in data.items: # Create all items
		sprite = Globals.item_scene.instantiate() # Create item
		items.add_child(sprite)
		sprite.scale = Vector2(item.scale.x, item.scale.y) * zoom * 0.01 # Set item properties
		sprite.position = Vector2(item.pos.x, -item.pos.y) * zoom
		sprite.rotation = -item.rotation
		sprite.z_index = item.depth
		
			# ITEM FILE
		file = FileAccess.open(game_path + "res/items/" + item.type + ".wog2", FileAccess.READ)
		item_data = JSON.parse_string(file.get_as_text())
		file = null
		
		for cur_item: Dictionary in item_data.items: # Loop through items
			for object: Dictionary in cur_item.objects: # Loop through item's objects
				sprite.texture = BOY_IMAGE.convert_texture(game_path + "res/items/images/" + XML_FINDER.find_xml_value(xml, object.name) + ".image")
	
	
	set_process(true) # Start processing input and drawing frames
	add_child(menu)
	
		# UI
	var type: Dictionary
	for index: int in Globals.ball_details.size(): # Create goo ball buttons
		type = Globals.ball_details[index]
		
		if type.sprite:
			new_ball_button(index)
	
	proj_name.text = data.title # Set level name


	# DRAW
func _draw() -> void:
	if !data: return
	
		# DRAW STRANDS
	var point_1: Vector2 = Vector2.ZERO
	var point_2: Vector2 = Vector2.ZERO
	var cur_uid: Dictionary # Current ball being used for UID/strand connections
	for strand: Dictionary in data.strands:
			# Point 1
		cur_uid = ball_uids[strand.ball1UID].ball_ref.pos
		point_1 = Vector2(cur_uid.x, -cur_uid.y)
			# Point 2
		cur_uid = ball_uids[strand.ball2UID].ball_ref.pos
		point_2 = Vector2(cur_uid.x, -cur_uid.y)
		
		draw_line(point_1 * zoom, point_2 * zoom, Globals.ball_details[strand.type].color, 2.0) # Draw strand
	
	
		# INPUT WITH DRAWING
	if holding_goo:
			# DRAG MODE
		if !line_mode:
			held_goo.pos.x = mouse_pos.x / zoom # Move goo with cursor
			held_goo.pos.y = -mouse_pos.y / zoom
			
			if !Input.is_action_pressed(&"Click"): # No longer holding goo
				holding_goo = false
			
			# LINE MODE
		else:
			draw_line(Vector2(held_goo.pos.x, -held_goo.pos.y) * zoom, mouse_pos, Color.WHITE, 5.0)
			
			if !Input.is_action_pressed(&"Click"): # No longer holding line
				if hovering_goo and hovered_goo != held_goo: # Add strand to hovered goo
					data.strands.append(
						{
							"ball1UID": held_goo.uid,
							"ball2UID": hovered_goo.uid,
							"type": held_goo.typeEnum,
							"filled": true
						}
					)
				
				holding_goo = false
	
	
		# DRAW BALLS
	hovering_goo = false # Reset if hovering goo
	var cur_color: Color = main_color # Current color for each item in balls array
	var details: Dictionary = {} # Ball details
	var dist_to_cur: float = 0.0 # Distance to cursor
	var ball_pos: Vector2 = Vector2.ZERO # Ball's visual position
	
		# Iterate through balls
	for ball: Dictionary in data.balls:
		ball_pos = Vector2(ball.pos.x, -ball.pos.y) * zoom # Cache ball's visual position
		details = Globals.ball_details[ball.typeEnum]
		
			# Isn't the currently selected goo
		if (!selected_goo or sel_goo.uid != ball.uid):
			cur_color = Color.WHITE if details.sprite else details.color
		else: cur_color = select_color
		
			# Cursor is not holding or hovering over any goo
		if (!holding_goo or line_mode) and !hovering_goo:
			dist_to_cur = mouse_pos.distance_to(ball_pos) # Get distance to mouse
			
				# Cursor is over ball, be selected
			if dist_to_cur < 12.0:
					# Set as hovered
				cur_color = select_color
				hovered_goo = ball
				hovering_goo = true
		
		
			# Draw ball
		if details["sprite"]: # Draw texture
			draw_texture(details.sprite, ball_pos - details.sprite.get_size() * 0.5, cur_color)
		else: # Draw color if has no texture
			draw_circle(ball_pos, 5.0, cur_color) # Draw circle


	# Process every frame
func _process(_delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	
		# Cursor control
	cur_dir.x = Input.get_axis(&"Left", &"Right")
	cur_dir.y = Input.get_axis(&"Up", &"Down")
	if cur_dir:
		camera.position += cur_dir * 2.0
	
	
			# INPUT
		# Presing click
	if Input.is_action_pressed(&"Click"):
		if hovering_goo:
				# Just pressed left click
			if Input.is_action_just_pressed(&"Click"):
				held_goo = hovered_goo
				hovering_goo = false
				holding_goo = true
				select_goo(hovered_goo)
			
			
			# Has selected goo - remove selection
		elif !holding_goo and selected_goo:
			select_goo()
		
		
		# Is pressing right click
	elif Input.is_action_pressed(&"Right_Click") and hovering_goo and not holding_goo:
		var strands_2_free: Array[Dictionary] = []
		
		for strand: Dictionary in data.strands: # Check all strands
			if hovered_goo.uid == strand.ball1UID or hovered_goo.uid == strand.ball2UID: # strand
				strands_2_free.append(strand)
		for strand: Dictionary in strands_2_free: # Delete queued strands
			data.strands.erase(strand)
		
		data.balls.erase(hovered_goo) # Erase goo ball
	
	
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
		# MOUSE
	if event is InputEventMouseButton:
			# ZOOM
		var pre_zoom: float = zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: # Zoom in
			zoom += 2.0
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: # Zoom out
			zoom -= 2.0
		
			# ITEMS
		if pre_zoom != zoom: # Zoom was changed
			var item: Sprite2D
			var items_nodes: Array[Node] = items.get_children()
			var item_data: Dictionary
			
			for index: int in data.items.size(): # Change position and size of sprites
				item = items_nodes[index]
				item_data = data.items[index] # This is the worst the shitcode gets I swear
				item.scale = Vector2(item_data.scale.x, item_data.scale.y) * zoom * 0.01
				item.position = Vector2(item_data.pos.x, -item_data.pos.y) * zoom


	# UI
func _Save_Pressed() -> void: # Save pressed
	file = FileAccess.open(pre_path, FileAccess.WRITE)
	file.store_line(JSON.stringify(data, "	", false))
	file.close()

func _load_pressed() -> void: # Load pressed
	load_popup.visible = true

func _popup_index_pressed(index: int) -> void: # Load popup pressed
	if index == 0: get_tree().reload_current_scene()
	else: load_popup.visible = false

func _file_select_canceled() -> void: # Canceled file select (no file)
	get_tree().quit()


	# MODES
func _line_mode_pressed() -> void: # Switched to line mode
	line_mode = !line_mode

func _hide_mode_pressed() -> void:
	items.visible = !items.visible


	# BALLS
func new_ball_button(typeEnum: int) -> void: # Create a ball spawning button
	var new_btn: Button = Globals.goo_button_scene.instantiate()
	var type: Dictionary = Globals.ball_details[typeEnum]
	
	goo_container.add_child(new_btn)
	new_btn.button_down.connect(new_ball.bind(typeEnum), 1)
	new_btn.icon = type.sprite
	new_btn.tooltip_text = type.name


func new_ball(typeEnum: int) -> void: # Create a ball
	holding_goo = true
	
	held_goo = Globals.ball_template.duplicate(true)
	held_goo.typeEnum = typeEnum
	held_goo.uid = uid_increment
	uid_increment += 1
	
	ball_uids[held_goo.uid] = {
		ball_ref = held_goo, # Original ball
		color = Globals.ball_details[held_goo.typeEnum].color, # Editor color
		strands = [] # Connections
	}
	
	data.balls.append(held_goo)


	# CURSOR
func select_goo(ball: Variant = null) -> void: # Select goo - TODO - make this work for items too
	#for node: Node in detail_container.get_children(): # Clear previous selection
		#node.queue_free()
	
	if ball:
		selected_goo = true
		sel_goo = ball
		
		#var cur_det: Label # Current detail
		#for key: String in ball.keys():
			#if ball[key] is bool:
				#cur_det = Globals.checkmark_scene.instantiate()
				#detail_container.add_child(cur_det)
				#cur_det.text = key
		
	else:
		selected_goo = false
