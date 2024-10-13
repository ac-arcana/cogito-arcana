class_name MultiplayerTabMenu
extends CogitoTabMenu
## A Connection menu system

@export var steam_p2p_connection_menu : SteamP2PConnectionMenu

## called by the pause menu when this menu is opened
func refresh_servers():
	steam_p2p_connection_menu.open_lobby_list(null)
