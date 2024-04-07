class_name MultiplayerPlayerSpawner
extends MultiplayerSpawner
## Spawn players for host and client into an MP game

## TODO: Clients should be placed in the same location as the host when they join

@export var player_scene : PackedScene

## dictionaries cannot be statically typed
## key will be a variant data representing a player, key will be a node which is the player's node
var players = {}

var player_position : Vector3 = Vector3.ZERO
var player_rotation : Vector3 = Vector3.ZERO

func _ready():
	spawn_function = _spawn_player


func spawn_player():
	if is_multiplayer_authority():
		
		destroy_single_player()
		spawn(1)
		
		if not multiplayer.peer_connected.is_connected(spawn):
			multiplayer.peer_connected.connect(spawn)
		if not multiplayer.peer_disconnected.is_connected(_despawn_player):
			multiplayer.peer_disconnected.connect(_despawn_player)
	
	
func destroy_single_player():
	var player : Node = get_tree().root.find_child("Player", true, false)
	
	## save the position and rotation so that when a player is spawned, they can be in the correct location
	player_position = (player as Node3D).global_position
	player_rotation = (player as Node3D).global_rotation
	
	if player:
		print("Player found, destroying")
		player.queue_free()
	else:
		printerr("No single player was found to destroy")


func _spawn_player(id = 1) -> Node:
	var player : Node = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	players[id] = player
	
	if multiplayer.is_server():
		print("SERVER: Player spawned with id: " + str(id))
	else:
		print("CLIENT: Player spawned with id: " + str(id))
	
	if is_multiplayer_authority():
		#FIXME: Can't open pause menu once this is done
		
		var player_hud = get_tree().root.find_child("Player_HUD", true, false)
		player.player_hud = player_hud.get_path()
		player_hud.player = player
		var pause_menu = get_tree().root.find_child("MultiplayerPauseMenu", true, false).get_path()
		player.pause_menu = pause_menu
		
		## set the new player to the same position and rotation as the old player
		player.position = player_position
		player.rotation = player_rotation
		## the connection mananger handled closing the menu, here we inform the new player of that
		player._on_pause_menu_resume()
		
	return player


func _despawn_player(id):
	players[id].queue_free()
	
	if multiplayer.is_server():
		print("SERVER: Player despawned with id: " + str(id))
	else:
		print("CLIENT: Player despawned with id: " + str(id))
	
	players.erase(id)
