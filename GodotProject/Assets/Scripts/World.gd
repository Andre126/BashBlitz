extends Node

const BashBot = preload("res://Assets/Scenes/BashBotR.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var num_players = 0;
export var debugMode = false;
export(Array, Material) var materials
var players = []

func isAnyoneNear(spawner):
	for i in players:
		if i.global_transform.origin.distance_to(spawner.global_transform.origin)<1:
			return true
	return false

func trySpawnAt(bot,spawner,name):
	if name == spawner.get_name():
		if isAnyoneNear(spawner):
			return false
		bot.global_transform.origin = spawner.global_transform.origin
		return true
	return false

func spawn(bot):
	var childs = get_children();
	for spawner in childs:
		if trySpawnAt(bot,spawner,"spawnPoint1"):
			return
		if trySpawnAt(bot,spawner,"spawnPoint2"):
			return
		if trySpawnAt(bot,spawner,"spawnPoint3"):
			return
		if trySpawnAt(bot,spawner,"spawnPoint4"):
			return
			
# Called when the node enters the scene tree for the first time.
func _ready():
	print("world")
	var conected = Input.get_connected_joypads()
	var childs = get_children();
	var numOfPlayers = 0
	if debugMode:
		numOfPlayers = num_players
	else:
		numOfPlayers = len(conected)
	for i in range(numOfPlayers):
		var scoreBoard = get_node("/root/Arena/scoreBoard"+str(i))
		var bot = BashBot.instance()
		scoreBoard.visible = true
		scoreBoard.setPlayerName(str(i))
		bot.Id = i
		add_child(bot)
		players.append(bot)
		spawn(bot)
	for i in range(numOfPlayers):
		var mesh = players[i].get_node("polySurface7")
		mesh.get_node("polySurface10").set_surface_material(0,materials[i])
		mesh.get_node("polySurface11").set_surface_material(0,materials[i])
		mesh.get_node("polySurface12").set_surface_material(0,materials[i])
		mesh.get_node("polySurface13").set_surface_material(0,materials[i])
func respawn(Id):
	var bot = players[Id] as BashBot
	spawn(bot)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(Input.is_action_pressed("ui_left")):
		players[0].linear_velocity = Vector3(-6,0,0)
	if(Input.is_action_pressed("ui_right")):
		players[0].linear_velocity = Vector3(6,0,0)
	if(Input.is_action_pressed("ui_up")):
		players[0].linear_velocity = Vector3(0,0,-6)
	if(Input.is_action_pressed("ui_down")):
		players[0].linear_velocity = Vector3(0,0,6)
	if(Input.is_action_pressed("dash")):
		players[0].damage(delta)

func _on_joy_connection_changed(device_id, connected):
	if connected:
		print(Input.get_joy_name(device_id))
	else:
		print("Keyboard")
