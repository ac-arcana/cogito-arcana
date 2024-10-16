class_name MultiplayerLevelSpawner
extends MultiplayerSpawner
## Spawn in a single player level and convert it for MP use.
## This also synchronizes which level is currently loaded for all players.

signal level_loaded

@export var start_level : PackedScene
@export var multiplayer_pause_menu : PackedScene

func _ready():
	spawn_function = _spawn_level
	add_spawnable_scene("res://COGITO/DemoScenes/COGITO_04_Demo_Lobby.tscn")
	
	## spawn the SP default level
	spawn(start_level.resource_path)
	_replace_pause_menu_with_mp_version.call_deferred()


## called when the level is spawned by the multiplayer spawner
func _spawn_level(packed_scene_path : String) -> Node:
	var scene : Node = load(packed_scene_path).instantiate()
	return scene


func _replace_pause_menu_with_mp_version():
	var pause_menu = find_child("PauseMenu", true, false)
	if not pause_menu:
		printerr("MultiplayerLevelSpawner could not find PauseMenu to replace")
		return
	
	## the default pause menu does not have the mp options, remove it
	var pause_menu_parent = pause_menu.get_parent()
	pause_menu.queue_free()
	
	## now add the pause menu with mp options
	var multiplayer_pause_menu_instance = multiplayer_pause_menu.instantiate()
	pause_menu_parent.add_child(multiplayer_pause_menu_instance)
	
	## finally, hook the player up to the new pause menu
	var player : CogitoPlayer = find_child("Player", true, false)
	player.pause_menu = multiplayer_pause_menu_instance.get_path()
	multiplayer_pause_menu_instance.resume.connect(player._on_pause_menu_resume) # Hookup resume signal from Pause Menu
	multiplayer_pause_menu_instance.close_pause_menu() # Making sure pause menu is closed on player scene load
	
	#level is now fully loaded
	level_loaded.emit()
