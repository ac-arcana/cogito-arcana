class_name CogitoMultiplayerPauseMenu
extends CogitoPauseMenu
## Extend the pause menu controller to include a multiplayer menu

@export var multiplayer_tab_menu: MultiplayerTabMenu

var just_opened : bool = false

func open_multiplayer_menu():
	multiplayer_tab_menu.show()
	multiplayer_tab_menu.nodes_to_focus[0].grab_focus.call_deferred()
	multiplayer_tab_menu.refresh_servers()
	game_menu.hide()

func open_pause_menu():
	super()
	get_tree().paused = false
	just_opened = true

func close_pause_menu():
	## make sure that any time the pause menu is closed by a connection manager
	## that the multiplayer tab is closed, too
	multiplayer_tab_menu.hide()
	super()

func _input(event):
	#used to prevent the menu closing the moment it is opened
	if just_opened:
		just_opened = false
	else:
		if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")) and not game_menu.visible:
			multiplayer_tab_menu.hide()
		super(event)
