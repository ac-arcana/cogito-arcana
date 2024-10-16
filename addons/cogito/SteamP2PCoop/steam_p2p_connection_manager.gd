class_name SteamP2PConnectionMenu
extends Node
## Manager for client and host for Steam Lobbies

@export var multiplayer_hint_icon : Texture2D
@export var lobbies_container : Container

var multiplayer_pause_menu : CogitoMultiplayerPauseMenu
var player_hud : CogitoPlayerHudManager
var multiplayer_player_spawner : MultiplayerPlayerSpawner

var lobby_id : int = 0
var lobby_max_players: int = 32
var steam_peer := SteamMultiplayerPeer.new()

var LOBBY_NAME: String = "COGITO"

func _ready():
	multiplayer_pause_menu = get_tree().root.find_child("MultiplayerPauseMenu", true, false)
	player_hud = get_tree().root.find_child("Player_HUD", true, false)
	multiplayer_player_spawner = get_tree().root.find_child("MultiplayerPlayerSpawner", true, false)
	steam_peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	LOBBY_NAME = str(Steam.getPersonaName() + "'s Lobby")


## used to get a list of available lobbies to join
func open_lobby_list(name_filter):
	## clear any previous lobbies
	if lobbies_container.get_child_count() > 0:
		for child in lobbies_container.get_children():
			child.queue_free()
	
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	if name_filter != null:
		Steam.addRequestLobbyListStringFilter("name", LOBBY_NAME, 0)  ## WIP NAME SEARCH FILTER
	
	Steam.requestLobbyList()
	print("Requesting Steam Lobby List")


## show the list of available lobbies when received from steam callback
func _on_lobby_match_list(lobbies):
	print("Steam Lobby list received")
	## lobby is a lobby id
	for lobby : int in lobbies:
		## get the name of the lobby
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		var button : Button = Button.new()
		button.set_text(str(lobby_name) + " | Player Count: " + str(member_count))
		button.set_size(Vector2(100,5))
		button.connect("pressed", Callable(self, "join_lobby").bind(lobby))
		
		lobbies_container.add_child(button)


func _on_host_steam_button_pressed():
	## lobby types: https://godotsteam.com/tutorials/lobbies/
	steam_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC, lobby_max_players)
	multiplayer.multiplayer_peer = steam_peer
	print("Starting Host...")
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Starting Host...")


## once the host button has been pressed, and the lobby is created, this will end up being called
func _on_lobby_created(connection_status, id):
	if connection_status:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", LOBBY_NAME)
		Steam.setLobbyJoinable(lobby_id, true)
		print("Lobby Created Successfully")
		player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Lobby Created Successfully")
		## _on_lobby_joined will also be called


## used when clicking a related lobby button
func join_lobby(id : int):
	steam_peer.connect_lobby(id)
	multiplayer.multiplayer_peer = steam_peer
	lobby_id = id
	print("Joining Lobby:%s" % id)
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Joining Lobby...")

## called by both host and client after joining
func _on_lobby_joined(_this_lobby_id: int, _permissions: int, _locked: bool, _response: int):
	multiplayer_pause_menu.close_pause_menu()
	print("Lobby Joined Successfully")
	player_hud._on_set_hint_prompt(multiplayer_hint_icon, "Lobby Joined Successfully")
	
	#spawn the client player
	multiplayer_player_spawner.spawn_player()


## called by the refresh button in the ui
func _on_refresh_button_pressed():
	open_lobby_list(null)


func _on_lobby_name_text_submitted(new_text):
	LOBBY_NAME = new_text # Set Lobby name to input for Hosting
	open_lobby_list(LOBBY_NAME) # Refresh lobby list using Lobby name as Search Filter


func _on_max_players_spin_box_value_changed(value):
	lobby_max_players = int(value)

