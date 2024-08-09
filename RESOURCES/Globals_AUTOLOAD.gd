extends Node


		# - VARIABLES -
	# Data
var ball_details: Array[Dictionary] = [ # Ball details based on enumType
	{sprite = null}, # Empty 1
		# Common 1
	{color = Color.WEB_GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Common_BALL.png"), name = "Common"},
		# Albino 2
	{color = Color.WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Albino_BALL.png"), name = "Albino"},
		# Ivy 3
	{color = Color.FOREST_GREEN, sprite = preload("res://RESOURCES/Scenes/Balls/Ivy_BALL.png"), name = "Ivy"},
		# Balloon 4
	{color = Color.RED, sprite = preload("res://RESOURCES/Scenes/Balls/Balloon_BALL.png"), name = "Balloon"},
		# Golf (Single) 5
	{color = Color.GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Goolf_BALL.png"), name = "Goolf (Single)"},
		# Anchor 6
	{color = Color.WEB_GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Anchor_BALL.png"), name = "Anchor"},
		# Launcher 7
	{color = Color.WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Launcher_BALL.png"), name = "Launcher"},
		# Goo Product 8
	{color = Color.DIM_GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Product_BALL.png"), name = "Product"},
		# Thruster 9
	{color = Color.DARK_RED, sprite = preload("res://RESOURCES/Scenes/Balls/Thruster_BALL.png"), name = "Thruster"},
		# Terrain ball 10
	{color = Color.NAVAJO_WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Cheese_BALL.png"), name = "Cheese/Terrain"},
		# Big Balloon 11
	{color = Color.REBECCA_PURPLE, sprite = preload("res://RESOURCES/Scenes/Balls/Big_Balloon_BALL.png"), name = "Big balloon"},
		# Conduit ball 12
	{color = Color.ANTIQUE_WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Conduit_BALL.png"), name = "Conduit/Liquid"},
		# Liquid Launcher 13
	{color = Color.LIGHT_PINK, sprite = null, name = "Liquid Launcher"},
		# White goo product 14
	{color = Color.WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Product_White_BALL.png"), name = "White Product"},
		# Enlarging goo 15
	{color = Color.HOT_PINK, sprite = preload("res://RESOURCES/Scenes/Balls/Grow_BALL.png"), name = "Enlarging"},
		# Bomb goo 16
	{color = Color.SLATE_GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Bomb_BALL.png"), name = "Bomb"},
		# Rope goo 17
	{color = Color.WHITE, sprite = null},
		# Detachable fish 18
	{color = Color.FIREBRICK, sprite = preload("res://RESOURCES/Scenes/Balls/Fish_BALL.png"), name = "Fish"},
		# Green bouncy melon goo 19
	{color = Color.GREEN, sprite = null, name = "Melon"},
		# Timebug 20
	{color = Color.WHITE, sprite = null, name = "Timebug"},
	{sprite=null},{sprite=null}, # Empty 21, 22
		# Fuse goo 23
	{color = Color.SADDLE_BROWN, sprite = preload("res://RESOURCES/Scenes/Balls/Fuse_BALL.png"), name = "Fuse"},
		# World map goo 24
	{color = Color.WHITE, sprite = null, name = "World map"},
		# Firework goo 25
	{color = Color.WHITE, sprite = null, name = "Fireworks"},
		# Light goo 26
	{color = Color.WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Light_BALL.png"), name = "Light"},
		# Neon goo (one strand) 27
	{color = Color.WHITE, sprite = null, name = "Neon (1 strand)"},
		# Neon goo (two strands) 28
	{color = Color.WHITE, sprite = null, name = "Neon (2 strands)"},
		# Adapter 29
	{color = Color.WHITE, sprite = null, name = "Anchor"},
		# Winch 30
	{color = Color.WHITE, sprite = null, name = "Big 1 strand"},
	{sprite=null}, # Empty 31
		# Shrinking goo 32
	{color = Color.CADET_BLUE, sprite = preload("res://RESOURCES/Scenes/Balls/Shrink_BALL.png"), name = "Shrinking"},
		# Invisible liquid ? 33
	{color = Color.WHITE, sprite = null, name = "Invisible liquid"},
		# Turquoise goolf ball 34
	{color = Color.TURQUOISE, sprite = null, name = "Goolf (turquoise)"},
		# Gravity cube 35
	{color = Color.WHITE, sprite = null, name = "Gravity cube"},
		# Invisible anchor 36
	{color = Color.WHITE, sprite = null, name = "Invisible anchor"},
		# Jelly goo eye 37
	{color = Color.WHITE, sprite = null, name = "Jelly goo eye"},
		# Jelly goo??? 38
	{color = Color.WHITE, sprite = null, name = "Jelly goo"}
]

	# Resources
var ball_template: Dictionary = JSON.parse_string(FileAccess.open("res://RESOURCES/Scenes/Balls/JSON/Ball_JSON.json", FileAccess.READ).get_as_text())
var item_template: Dictionary = JSON.parse_string(FileAccess.open("res://RESOURCES/Scenes/Items/JSON/Item_JSON.json", FileAccess.READ).get_as_text())

var debug_texture: CompressedTexture2D = preload("res://Level_Juicer_ICON.png") # Debug texture
var item_scene: PackedScene = preload("res://RESOURCES/Scenes/Items/Item_SCENE.tscn")

	# UI
var goo_button_scene: PackedScene = preload("res://RESOURCES/Scenes/UI/Buttons/Goo_Button_SCENE.tscn")
var goo_dropdown_scene: PackedScene = preload("res://RESOURCES/Scenes/UI/Buttons/Goo_Dropdown_SCENE.tscn")
var checkmark_scene: PackedScene = preload("res://RESOURCES/Scenes/UI/Buttons/Checkmark_SCENE.tscn")


	# Items
var item_groups: Dictionary = {
	"Hazards": { 
		"icon": preload("res://RESOURCES/Scenes/UI/Textures/Hazards_ITEM_GROUP.png"),
		"tooltip": "Things that slice, dice, burn, and generally kill goo",
		"items": [
			#{"type": "d759dc7a-14f1-47b5-9d0d-3b1fec52a03a", "name": "GearBasic"}, # Decor gear
			{"type": "8d5e7328-4a5d-4f11-a544-3835ced3e9ee", "name": "Gear1BlurWhite"},
			{"type": "61af9273-0b95-4d67-86c9-d4f9d9f8313e", "name": "Gear1BlurGray"},
			{"type": "61af9273-d9d0-4872-8304-4d11c41a5831", "name": "Gear1Blur"},
		]
	},
	
	"Nature": {
		"icon": preload("res://RESOURCES/Scenes/UI/Textures/Nature_ITEM_GROUP.png"),
		"tooltip": "Flora and natural decor",
		"items": [
			{"type": "09053897-e05f-4e35-8ea2-30fd87805ba8", "name": "Bush1"},
			{"type": "a5fd4181-ab99-4a1d-8165-e8d03522a873", "name": "BushUni"},
			{"type": "61af9272-4c9b-4c5e-9949-3661ffb87ab9", "name": "Cloud1"},
			{"type": "61af9272-0402-4ab5-a8e3-b1fcc1096015", "name": "Cloud2"},
			{"type": "059c2646-80d1-4c16-859b-2d5a0092a4c8", "name": "SignPainterSign"},
			{"type": "61af9274-06c9-47bb-82e0-9b6094a0afb4", "name": "Pool"},
			{"type": "c70e624f-5997-4819-956c-f62a9ed8082b", "name": "Rocks"},
			{"type": "4fd66c29-26f7-4d00-bbc2-139a3503ccc0", "name": "Cloud_Big1"},
			{"type": "61af9273-a579-4819-9837-f3c4aa9a7efb", "name": "PipeInLiquid"},
			{"type": "152347d8-ed08-47bc-9100-a1ccefcb3389", "name": "ChainHeadDynamic"},
			{"type": "00826534-fe3c-4ccb-b906-c95f06bf3fc4", "name": "ChainHeadTotem"},
			{"type": "66a25152-fdd2-4f14-bb63-2ba53d131e0f", "name": "LevelExit"}
		]
	}
}

var item_draw_overrides: Dictionary = { # Item drawing overrides
	"61af9273-a579-4819-9837-f3c4aa9a7efb" = preload("res://RESOURCES/Scenes/Items/Pipe_Fluid_ITEM.png"),
	"66a25152-fdd2-4f14-bb63-2ba53d131e0f" = preload("res://RESOURCES/Scenes/Items/Pipe_ITEM.png")
}
