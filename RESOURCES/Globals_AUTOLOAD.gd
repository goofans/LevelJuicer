extends Node


		# VARIABLES
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
		# Ball shooter 7
	{color = Color.WHITE, sprite = null},
		# Goo Product 8
	{color = Color.DIM_GRAY, sprite = preload("res://RESOURCES/Scenes/Balls/Product_BALL.png"), name = "Product"},
		# Flamethrower 9
	{color = Color.DARK_RED, sprite = null},
		# Terrain ball 10
	{color = Color.NAVAJO_WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Cheese_BALL.png"), name = "Cheese/Terrain"},
		# Big Balloon 11
	{color = Color.REBECCA_PURPLE, sprite = preload("res://RESOURCES/Scenes/Balls/Big_Balloon_BALL.png"), name = "Big balloon"},
		# Conduit ball 12
	{color = Color.ANTIQUE_WHITE, sprite = preload("res://RESOURCES/Scenes/Balls/Conduit_BALL.png"), name = "Conduit/Liquid"},
		# Tentacle 13
	{color = Color.LIGHT_PINK, sprite = null},
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
var ball_template: Dictionary = JSON.parse_string(FileAccess.open("res://RESOURCES/Scenes/Balls/JSON/ball.json", FileAccess.READ).get_as_text())
var debug_texture: CompressedTexture2D = preload("res://Level_Juicer_ICON.png") # Debug texture
var item_scene: PackedScene = preload("res://RESOURCES/Scenes/Items/Item_SCENE.tscn")

	# UI
var goo_button_scene: PackedScene = preload("res://RESOURCES/Scenes/UI/Buttons/Goo_Button_SCENE.tscn")
var checkmark_scene: PackedScene = preload("res://RESOURCES/Scenes/UI/Buttons/Checkmark_SCENE.tscn")
