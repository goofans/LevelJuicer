extends Node2D

		# NOTE #
	# Originally I wrote an explanation for why the code looks like this
	# but there is no justification for how the code is written, I am sorry


		# - VARIABLES -
	# FILES
var save_file: FileAccess # Users save data
var game_path: String # Path to wog2.exe
var data: Dictionary # Level data
var file: FileAccess # File access
var pre_path: String
@onready var file_dialog: FileDialog = $Level_FILE
@onready var game_dialog: FileDialog = $Game_FILE

var item_xml: XMLParser = XMLParser.new() # Parse XML resources


	# ARRAYS - TODO - cache positions in ball UIDs for optimization?
var ball_uids: Dictionary = {} # Ball details for visualizing in the editor
var item_uids: Dictionary = {}
var item_uid_data: Dictionary = {} # Fetch an items name with it's UID
@onready var items: Node2D = $Items # Node2D that contains all item sprites

var ball_buttons: Array[Button] = [] # Array of ball buttons
var item_dropdowns: Array[OptionButton] = [] # Array of item dropdowns


	# VISUALS
var main_color: Color = Color.WHITE # Main color
var select_color: Color = Color("ffa596") # Selection color for modulating


	# MOUSE - TODO - add multi selection
var sel_goo: Dictionary # Selected goo
var sel_goo_sprite: Node2D # Selected item sprite2D node
var held_goo: Dictionary # Currently held goo
var hovered_goo: Dictionary # Currently hovered goo

var holding_goo: bool = false # If holding goo
var hovering_goo: bool = false # If hovering over goo
var selected_goo: bool = false # If a goo ball is currently selected

var items_toggled: bool = false # If currently editing items

var zoom: float = 19.05 # Camera zoom
var cur_dir: Vector2 = Vector2.ZERO # Cursor direction
@onready var camera: Camera2D = $Camera # Camera
var mouse_pos: Vector2 = Vector2.ZERO # Cursor position

var line_mode: bool = false # Is drawing lines
@onready var line_button: Button = $Control_LAYER/Control/Tool_PANEL/Toolbar_CONTAINER/Line_BUTTON
var line_icon: CompressedTexture2D = preload("res://RESOURCES/Scenes/UI/Textures/Line_Mode_SPRITE.png")
var rotate_icon: CompressedTexture2D = preload("res://RESOURCES/Scenes/UI/Textures/Rotate_Item_TEXTURE.png")


	# UI
@onready var goo_container: HBoxContainer = $Control_LAYER/Control/Ball_PANEL/Scroll_CONTAINER/H_Box_CONTAINER # Contains the goo spawn buttons
@onready var load_popup: PopupMenu = $Load_POPUP

@onready var menu: CanvasLayer = $Control_LAYER # Entirety of the menu
@onready var proj_name: Label = $Control_LAYER/Control/Name_LABEL # Name of the level
@onready var act_label: Label = $Control_LAYER/Control/Action_LABEL
@onready var detail_container: VBoxContainer = $Control_LAYER/Control/Info_PANEL/Scroll_CONTAINER/V_Box_CONTAINER

@onready var focus_stealer: Control = $Control_LAYER/Control/Focus_Stealer

@onready var terrain_groups: OptionButton = $Control_LAYER/Control/Tool_PANEL/Terrain_Groups_DROPDOWN
var item_sprites: Array[Node]


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
	
	item_xml.open(game_path + "res/items/images/_resources.xml")
	
	
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
	for item: Dictionary in data.items: # Create all items
		var item_sprite: Node2D = new_item_sprite(item)
		item_uids[item.uid] = {
			"sprite" = item_sprite,
		}
	
	
	
	set_process(true) # Start processing input and drawing frames
	add_child(menu)
	
		# UI
	var type: Dictionary
	var terrain_icon: CompressedTexture2D = preload("res://RESOURCES/Scenes/UI/Textures/Terrain_Groups_TEXTURE.png")
	
		# BUTTONS
	for index: int in Globals.ball_details.size(): # Create goo ball buttons
		type = Globals.ball_details[index]
		if type.sprite:
			new_ball_button(index)
	
	for group: String in Globals.item_groups.keys(): # Create item dropdown buttons
		new_item_button(group) # NOTE - these are not added to the scene tree yet
	
	for index: int in data.terrainGroups.size(): # Terrain groups dropdown
		terrain_groups.add_icon_item(terrain_icon, "Group " + str(index))
	
	proj_name.text = data.title # Set level name
	new_undo("Level loaded successfully! RMB - delete | Scroll - zoom | WASD - move")



	# DRAW
func _draw() -> void: # Draw every frame
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
			
			if items_toggled: sel_goo_sprite.position = mouse_pos # Update item sprite
			
			if !Input.is_action_pressed(&"Click"): # No longer holding goo
				holding_goo = false
			
			# ROTATE ITEM MDOE
		elif items_toggled:
			sel_goo_sprite.look_at(mouse_pos)
			sel_goo.rotation = -sel_goo_sprite.rotation
			
			if !Input.is_action_pressed(&"Click"):
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
			
				# If editing balls
			if !items_toggled:
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
	if items_toggled: # If editing items
		item_sprites = items.get_children() # Get all item sprites
		var sprite: Node2D
		var item_data: Dictionary
		
		for index: int in item_sprites.size():
			sprite = item_sprites[index] # Get current item in loop
			item_data = data.items[index] # Get item's data
			
				# Check if currently selected item
			cur_color = Color.WHITE if !selected_goo or sel_goo.uid != item_data.uid else select_color
			
					# Cursor is not holding or hovering over any items
			if (!holding_goo or line_mode) and !hovering_goo:
				dist_to_cur = mouse_pos.distance_to(sprite.global_position) # Get distance to mouse
				
					# Cursor is over item, be selected
				if dist_to_cur < 70.0:
						# Set as hovered item
					cur_color = select_color
					hovered_goo = item_data
					hovering_goo = true
			
			sprite.modulate = cur_color


	# Process every frame
func _process(_delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	
		# Cursor control
	if focus_stealer.has_focus():
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
			
			
			# Is pressing right click
		elif Input.is_action_pressed(&"Right_Click") and hovering_goo and !holding_goo:
					# DELETE
				# Delete ball
			if !items_toggled:
				var strands_2_free: Array[Dictionary] = []
				
					# Delete ball
				for strand: Dictionary in data.strands: # Check all strands
					if hovered_goo.uid == strand.ball1UID or hovered_goo.uid == strand.ball2UID: # strand
						strands_2_free.append(strand)
				for strand: Dictionary in strands_2_free: # Delete queued strands
					data.strands.erase(strand)
				
				new_undo("Ball deleted!")
				data.terrainBalls.erase(data.balls.find(hovered_goo)) # Remove from terrain balls
				data.balls.erase(hovered_goo) # Erase goo ball
				
				# Delete item
			else:
				items.get_children()[data.items.find(hovered_goo)].free()
				data.items.erase(hovered_goo)
				new_undo("Item (" + item_uid_data[hovered_goo.type].name + ") deleted!")
	
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
		# MOUSE
	if focus_stealer.has_focus() and event is InputEventMouseButton:
			# ZOOM
		var pre_zoom: float = zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: # Zoom in
			zoom += 2.0
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: # Zoom out
			zoom = max(0.0, zoom - 2.0)
		
			# ITEMS
		if pre_zoom != zoom: # Zoom was changed
			var item: Node2D
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
		new_undo("Level saved to " + pre_path + " successfully!")
	else:
		new_undo("ERROR! - Failed to save! File path changed or insufficient priviledges")

func _load_pressed() -> void: # Load pressed
	load_popup.visible = true

func _popup_index_pressed(index: int) -> void: # Load popup pressed
	if index == 0: get_tree().reload_current_scene()
	else: load_popup.visible = false

func _file_select_canceled() -> void: # Canceled file select (no file)
	get_tree().quit()

func new_undo(text: String) -> void: # Sets last detailed action
	act_label.text = text



	# MODES
func _line_mode_pressed() -> void: # Switched to line mode
	line_mode = !line_mode
	new_undo("Toggled " + ("rotation" if items_toggled else "line") + " mode to " + str(line_mode))

func _hide_mode_pressed() -> void:
	items.visible = !items.visible
	new_undo("Toggled item visualization to " + str(items.visible))



	# BALLS
func new_ball_button(typeEnum: int) -> void: # Create a ball spawning button
	var new_btn: Button = Globals.button_scene.instantiate()
	var type: Dictionary = Globals.ball_details[typeEnum]
	
	goo_container.add_child(new_btn)
	new_btn.button_down.connect(new_ball.bind(typeEnum), 1)
	new_btn.icon = type.sprite
	new_btn.tooltip_text = type.name
	ball_buttons.append(new_btn)


func new_ball(typeEnum: int) -> void: # Create a ball
	holding_goo = true
	
	held_goo = Globals.ball_template.duplicate(true)
	held_goo.typeEnum = typeEnum # Set stats
	held_goo.uid = uid_increment
		# Add to terrain balls, set id if is terrain
	data.terrainBalls.append({"group": max(0, terrain_groups.selected - 1) if typeEnum == 10 else -1})
	
	uid_increment += 1
	
	ball_uids[held_goo.uid] = {
		ball_ref = held_goo, # Original ball
		color = Globals.ball_details[typeEnum].color, # Editor color
		visible = true # If visible in editor
	}
	
	data.balls.append(held_goo)
	new_undo("New " + Globals.ball_details[typeEnum].name + " ball spawned!")



	# ITEMS
func new_item_button(group: String) -> void: # create dropdown options for each group
	var new_btn: OptionButton = Globals.dropdown_scene.instantiate()
	var item_data: Dictionary = Globals.item_groups[group]
	
	new_btn.item_selected.connect(func(id: int) -> void:
		new_btn.selected = -1
		new_item(group, id)
		new_btn.icon = item_data.icon
	, 1)
	new_btn.tooltip_text = item_data.tooltip
	
	for item: Dictionary in item_data.items: # Add items to dropdown
		new_btn.add_item(item.name)
	
	item_dropdowns.append(new_btn)
	new_btn.selected = -1
	new_btn.icon = item_data.icon


func new_item(group: String, id: int) -> void:
	var item_data: Dictionary = Globals.item_groups[group].items[id]
	holding_goo = true
	
	held_goo = Globals.item_template.duplicate(true)
	held_goo.type = item_data.type # Set stats
	held_goo.uid = uid_increment
	
	uid_increment += 1
	data.items.append(held_goo)
	
	sel_goo_sprite = new_item_sprite(held_goo)
	new_undo("New " + item_data.name + " spawned!")


func _edit_mode_swapped() -> void: # Swapped to different edit mode
	items_toggled = !items_toggled
	line_mode = false
	new_undo("Toggled editing items to " + str(items_toggled))
	
		# SWAP GOO/ITEM BAR
	if items_toggled: # Items toggled on
		line_button.icon = rotate_icon
		line_button.tooltip_text = "Toggle rotation mode"
		for button: Button in ball_buttons:
			goo_container.remove_child(button)
		for button: OptionButton in item_dropdowns:
			goo_container.add_child(button)
		
		# Items toggled off
	else:
		line_button.icon = line_icon
		line_button.tooltip_text = "Toggle line mode"
		for button: OptionButton in item_dropdowns:
			goo_container.remove_child(button)
		for button: Button in ball_buttons:
			goo_container.add_child(button)


func new_item_sprite(item: Dictionary) -> Sprite2D: # Create sprite2D for item
	var item_group: Node2D # Item itself
	var item_sprite: Sprite2D # Item objects
	var item_data: Dictionary # Item name from .wog2
	
	item_group = Node2D.new() # Create item
	items.add_child(item_group)
	item_group.scale = Vector2(item.scale.x, item.scale.y) * zoom * 0.005 # Set item properties
	item_group.global_position = Vector2(item.pos.x, -item.pos.y) * zoom
	item_group.rotation = -item.rotation
	item_group.z_index = item.depth
	
	
		# ITEM FILE
	file = FileAccess.open(game_path + "res/items/" + item.type + ".wog2", FileAccess.READ)
	item_data = JSON.parse_string(file.get_as_text())
	file = null
	#var color: int
	
	for cur_item: Dictionary in item_data.items: # Loop through items
		for object in cur_item.objects:
			item_sprite = Globals.item_scene.instantiate() # Create object
			item_group.add_child(item_sprite)
			
			#color = object.color
			#item_sprite.modulate = Color(
				#((color & 0x00FF0000) >> 16) / 255.0, 
				#(color & 0x0000FF00) / 255.0, 
				#((color & 0x000000FF) << 16) / 255.0,
				#(color & 0xFF000000) / 255.0,
			#)
			item_sprite.z_index = object.depthOffset
			
				# DRAWING
			if Globals.item_draw_overrides.has(cur_item.uuid): # Sprite to draw specified in autoload
				item_sprite.texture = Globals.item_draw_overrides[cur_item.uuid]
			else: # Get item sprite
				item_sprite.texture = BOY_IMAGE.convert_texture(game_path + "res/items/images/" + XML_FINDER.find_xml_value(item_xml, object.name) + ".image")
			
			item_sprite.position = Vector2( # Set object position
				-object.position.x, object.position.y
			) * zoom
			item_sprite.scale = Vector2(object.scale.x, object.scale.y) * zoom * 0.05
			item_sprite.rotation = -object.rotation
		
		item_uid_data[cur_item.uuid] = {
			"name": cur_item.name,
		}
	
	return item_group



	# CURSOR
func select_goo(ball: Dictionary) -> void: # Select goo - TODO - make this work for items too
	if ball: # Selected something
		selected_goo = true
		if items_toggled: # ITEM
			sel_goo_sprite = items.get_children()[data.items.find(ball)]
			new_undo("Item (" + item_uid_data[ball.type].name + ") selected!")
		else: # BALL
			new_undo(Globals.ball_details[ball.typeEnum].name + " ball (UID " + str(ball.uid) + ") selected!")
		sel_goo = ball
		
			# DETAILS
		set_details()


func set_details() -> void: # Create details
	for node: Node in detail_container.get_children(): # Clear previous selection
		node.queue_free()
	
	var cur_det: VBoxContainer # Current detail
	for key: String in sel_goo.keys():
		if sel_goo[key] is bool:
			cur_det = Globals.checkbox_scene.instantiate()
			detail_container.add_child(cur_det)
			cur_det.label.text = key
			cur_det.checkbox.button_pressed = sel_goo[key]
			
			cur_det.checkbox.pressed.connect(set_from_checkbox.bind(cur_det.checkbox, key))
			
		elif sel_goo[key] is String or sel_goo[key] is float or sel_goo[key] is int:
			cur_det = Globals.input_scene.instantiate()
			detail_container.add_child(cur_det)
			cur_det.label.text = key
			cur_det.input.text = str(sel_goo[key])
			
			cur_det.input.text_changed.connect(set_from_input.bind(cur_det.input, key))


func set_from_checkbox(node: CheckBox, key: String) -> void: # Set goo properties from checkbox
	sel_goo[key] = node.button_pressed
	update_goo_properties()

func set_from_input(node: TextEdit, key: String) -> void: # Set goo properties from input
	print(1)
	if !node.text: return
	print(2)
	
	if node.text.is_valid_float():
		sel_goo[key] = float(node.text)
		print(sel_goo[key])
	elif node.text.is_valid_int():
		sel_goo[key] = int(node.text)
	else:
		sel_goo[key] = node.text
	update_goo_properties()

func update_goo_properties() -> void: # Apply goo properties
	if items_toggled:
		if sel_goo.rotation is float or sel_goo.rotation is int: sel_goo_sprite.rotation = -sel_goo.rotation
		else: sel_goo.rotation = 0.0



		# TERRAIN
	# Terrain group selected
func _terrain_group_selected(index: int) -> void:
	var group_id: int # Used for checking for balls from terrainBalls
	
	if index != 0: # User selected a specific terrain group
		new_undo("Switched to terrain group " + str(index - 1))
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
		new_undo("Switched to all terrain groups! New terrain balls will default to group 0")
		for ball: Dictionary in data.balls:
			ball_uids[ball.uid].visible = true
