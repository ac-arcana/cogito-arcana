extends Node
## Manages connections, hosting, and disconnect for LAN games

@export var multiplayer_hint_icon : Texture2D

var multiplayer_pause_menu : CogitoMultiplayerPauseMenu
var player_hud : CogitoPlayerHudManager
var enet_peer := ENetMultiplayerPeer.new()
var multiplayer_player_spawner : MultiplayerPlayerSpawner

func _ready():
	multiplayer_pause_menu = get_tree().root.find_child("MultiplayerPauseMenu", true, false)
	player_hud = get_tree().root.find_child("Player_HUD", true, false)
	multiplayer_player_spawner = get_tree().root.find_child("MultiplayerPlayerSpawner", true, false)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_host_lan_button_pressed():
	enet_peer.create_server(1027)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer_pause_menu.close_pause_menu()
	print("Server opened on port %s" % 1027)
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Server Started")
	
	#spawn the host player
	multiplayer_player_spawner.spawn_player()


func _on_join_localhost_button_pressed():
	enet_peer.create_client("127.0.0.1", 1027)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer_pause_menu.close_pause_menu()
	print("Connecting to %s:%s" % ["127.0.0.1", 1027])
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Connecting to %s:%s" % ["127.0.0.1", 1027])


func _on_connection_failed():
	print("Connection to Server Failed")
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Connection to Server Failed")


func _on_connected_to_server():
	print("Connected Successfully")
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Connected to Server")

	#spawn the client player
	multiplayer_player_spawner.spawn_player()
