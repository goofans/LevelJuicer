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

	# ARRAYS - TODO - cache positions in ball UIDs for optimization?
var ball_uids: Dictionary = {} # Ball details for visualizing in the editor
@onready var items: Node2D = $Items # Node2D that contains all item sprites


	# VISUALS
var main_color: Color = Color.WHITE # Main color
var select_color: Color = Color("ffa596") # Selection color for modulating


	# MOUSE - TODO - add multi selection
var sel_goo: Dictionary # Selected goo
var sel_item: Sprite2D # Selected item sprite2D node
var held_goo: Dictionary # Currently held goo
var hovered_goo: Dictionary # Currently hovered goo

var holding_goo: bool = false # If holding goo
var hovering_goo: bool = false # If hovering over goo
var selected_goo: bool = false # If a goo ball is currently selected

var hovering_item: bool = false # If an item is currently hovered (hovered_goo is still the reference)
var selected_item: bool = false # If an item is currently selected (sel_item is the reference!!)

var zoom: float = 60.0 # Camera zoom
var cur_dir: Vector2 = Vector2.ZERO # Cursor direction
@onready var camera: Camera2D = $Camera # Camera
var mouse_pos: Vector2 = Vector2.ZERO # Cursor position

var line_mode: bool = false # Is drawing lines


	# UI
@onready var goo_container: HBoxContainer = $Control_LAYER/Control/Ball_PANEL/Scroll_CONTAINER/H_Box_CONTAINER # Contains the goo spawn buttons
@onready var load_popup: PopupMenu = $Load_POPUP

@onready var menu: CanvasLayer = $Control_LAYER # Entirety of the menu
@onready var proj_name: Label = $Control_LAYER/Control/Name_LABEL # Name of the level
@onready var act_label: Label = $Control_LAYER/Control/Action_LABEL
@onready var detail_container: VBoxContainer = $Control_LAYER/Control/Info_PANEL/V_Box_CONTAINER

@onready var terrain_groups: OptionButton = $Control_LAYER/Control/Tool_PANEL/Terrain_Groups_DROPDOWN


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
	act_label.text = "Level loaded successfully!"
	
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
	
	if (!FileAccess.file_exists("user://user_data.dat")):
		save_file = FileAccess.open("user://user_data.dat", FileAccess.WRITE)
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
			visible = true # Visible in editor
		}
	
	
		# ITEMS
	var item_sprite: Sprite2D
	var item_data: Dictionary # Item name from .wog2
	var item_xml: XMLParser = XMLParser.new()
	item_xml.open(game_path + "res/items/images/_resources.xml")
	
	for item: Dictionary in data.items: # Create all items
		if item.uid > uid_increment: uid_increment = item.uid + 1
		
		item_sprite = Globals.item_scene.instantiate() # Create item
		items.add_child(item_sprite)
		item_sprite.scale = Vector2(item.scale.x, item.scale.y) * zoom * 0.005 # Set item properties
		item_sprite.position = Vector2(item.pos.x, -item.pos.y) * zoom
		item_sprite.rotation = -item.rotation
		item_sprite.z_index = item.depth
		
			# ITEM FILE
		file = FileAccess.open(game_path + "res/items/" + item.type + ".wog2", FileAccess.READ)
		item_data = JSON.parse_string(file.get_as_text())
		file = null
		
		for cur_item: Dictionary in item_data.items: # Loop through items
			for object: Dictionary in cur_item.objects: # Loop through item's objects
				item_sprite.texture = BOY_IMAGE.convert_texture(game_path + "res/items/images/" + XML_FINDER.find_xml_value(item_xml, object.name) + ".image")
	
	
	set_process(true) # Start processing input and drawing frames
	add_child(menu)
	
		# UI
	var type: Dictionary
	var terrain_icon: CompressedTexture2D = preload("res://RESOURCES/Scenes/UI/Textures/Terrain_Groups_TEXTURE.png")
	for index: int in Globals.ball_details.size(): # Create goo ball buttons
		type = Globals.ball_details[index]
		
		if type.sprite:
			new_ball_button(index)
	
	for index: int in data.terrainGroups.size(): # Terrain groups dropdown
		terrain_groups.add_icon_item(terrain_icon, "Group " + str(index))
	
	proj_name.text = data.title # Set level name


	# DRAW
func _draw() -> void:
	if !data: return
	
		# DRAW STRANDS
	var point_1: Vector2 = Vector2.ZERO
	var point_2: Vector2 = Vector2.ZERO
	var cur_uid: Dictionary # Current ball being used for UID/strand connections
	var p1_ball: Dictionary # Point 1 ball for checking if visible
	for strand: Dictionary in data.strands:
		p1_ball = ball_uids[strand.ball1UID]
		if p1_ball.visible:
				# Point 1
			cur_uid = p1_ball.ball_ref.pos
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
			
			if selected_item: sel_item.position = mouse_pos # Update item sprite
			
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
		if ball_uids[ball.uid].visible: # If ball is visible in editor
			ball_pos = Vector2(ball.pos.x, -ball.pos.y) * zoom # Cache ball's visual position
			details = Globals.ball_details[ball.typeEnum]
			
				# Isn't the currently selected goo
			if !selected_goo or sel_goo.uid != ball.uid:
				cur_color = Color.WHITE if details.sprite else details.color
			else: cur_color = select_color
			
				# Cursor is not holding or hovering over any goo
			if (!holding_goo or line_mode) and !hovering_goo:
				dist_to_cur = mouse_pos.distance_to(ball_pos) # Get distance to mouse
				
					# Cursor is over ball, be selected
				if dist_to_cur < 12.0:
						# Set as hovered goo
					cur_color = select_color
					hovered_goo = ball
					hovering_goo = true
			
			
				# Draw ball
			if details["sprite"]: # Draw texture
				draw_texture(details.sprite, ball_pos - details.sprite.get_size() * 0.5, cur_color)
			else: # Draw color if has no texture
				draw_circle(ball_pos, 5.0, cur_color) # Draw circle
	
	
		# ITEMS
	var item_sprites: Array[Node] = items.get_children()
	var sprite: Sprite2D
	var item_data: Dictionary
	hovering_item = false
	for index: int in item_sprites.size():
		sprite = item_sprites[index]
		item_data = data.items[index]
		
			# Check if currently selected item
		cur_color = Color.WHITE if !selected_goo or sel_goo.uid != item_data.uid else select_color
		
				# Cursor is not holding or hovering over any items
		if (!holding_goo or line_mode) and !hovering_goo and !hovering_item:
			dist_to_cur = mouse_pos.distance_to(sprite.global_position) # Get distance to mouse
			
				# Cursor is over item, be selected
			if dist_to_cur < 50.0:
					# Set as hovered item
				cur_color = select_color
				hovered_goo = item_data
				hovering_goo = true
				hovering_item = true # Mark as item
		
		sprite.self_modulate = cur_color


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
	elif Input.is_action_pressed(&"Right_Click") and hovering_goo and !holding_goo:
				# DELETE
			# Delete ball
		if !hovering_item:
			var strands_2_free: Array[Dictionary] = []
			
				# Delete ball
			for strand: Dictionary in data.strands: # Check all strands
				if hovered_goo.uid == strand.ball1UID or hovered_goo.uid == strand.ball2UID: # strand
					strands_2_free.append(strand)
			for strand: Dictionary in strands_2_free: # Delete queued strands
				data.strands.erase(strand)
			
			act_label.text = "Ball deleted!"
			data.terrainBalls.erase(data.balls.find(hovered_goo)) # Remove from terrain balls
			data.balls.erase(hovered_goo) # Erase goo ball
			
			# Delete item
		else:
			items.get_children()[data.items.find(hovered_goo)].free()
			data.items.erase(hovered_goo)
			act_label.text = "Item deleted!"
	
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
				item.scale = Vector2(item_data.scale.x, item_data.scale.y) * zoom * 0.005
				item.position = Vector2(item_data.pos.x, -item_data.pos.y) * zoom


	# UI
func _Save_Pressed() -> void: # Save pressed
	file = FileAccess.open(pre_path, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(data, "	", false))
		file.close()
		act_label.text = "Level saved to " + pre_path + " successfully!"
	else:
		act_label.text = "ERROR! - Failed to save! File path changed or insufficient priviledges"

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
	act_label.text = "Toggled line mode to " + str(line_mode)

func _hide_mode_pressed() -> void:
	items.visible = !items.visible
	act_label.text = "Toggled item visualization to " + str(items.visible)


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
	held_goo.typeEnum = typeEnum # Set stats
	held_goo.uid = uid_increment
		# Add to terrain balls, set id if is terrain
	data.terrainBalls.append({"group": max(0, terrain_groups.selected - 1) if typeEnum == 10 else -1})
	print(terrain_groups.selected)
	
	uid_increment += 1
	
	ball_uids[held_goo.uid] = {
		ball_ref = held_goo, # Original ball
		color = Globals.ball_details[typeEnum].color, # Editor color
		visible = true # If visible in editor
	}
	
	data.balls.append(held_goo)
	act_label.text = "New " + Globals.ball_details[typeEnum].name + " ball spawned!"


	# CURSOR
func select_goo(ball: Variant = null) -> void: # Select goo - TODO - make this work for items too
	#for node: Node in detail_container.get_children(): # Clear previous selection
		#node.queue_free()
	
	if ball:
		act_label.text = "Ball UID " + str(ball.uid) + " selected!"
		selected_goo = true
		if hovering_item: 
			selected_item = true
			sel_item = items.get_children()[data.items.find(ball)]
		sel_goo = ball
		
			# DETAILS
		#var cur_det: Label # Current detail
		#for key: String in ball.keys():
			#if ball[key] is bool:
				#cur_det = Globals.checkmark_scene.instantiate()
				#detail_container.add_child(cur_det)
				#cur_det.text = key
		
	else:
		act_label.text = "Unselected ball"
		selected_goo = false
		selected_item = false


		# - TERRAIN -
	# Terrain group selected
func _terrain_group_selected(index: int) -> void:
	var group_id: int # Used for checking for balls from terrainBalls
	
	if index != 0: # User selected a specific terrain group
		act_label.text = "Switched to terrain group " + str(index - 1)
		var ball: Dictionary
		for ind: int in data.balls.size():
			ball = data.balls[ind]
			
			if ball.typeEnum == 10:
				group_id = data.terrainBalls[ind].group
				
				if max(0, group_id) == index - 1:
					ball_uids[ball.uid].visible = true
				else:
					ball_uids[ball.uid].visible = false
		
	else: # User pressed show all
		act_label.text = "Switched to all terrain groups! New terrain balls will default to group 0"
		for ball: Dictionary in data.balls:
			ball_uids[ball.uid].visible = true
