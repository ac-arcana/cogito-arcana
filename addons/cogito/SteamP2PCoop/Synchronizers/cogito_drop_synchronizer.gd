class_name CogitoDropSynchronizer
extends Node

var local_player : MultiplayerPlayer

#gets a signal from the multiplayer_player_spawner
func _on_multiplayer_player_spawner_local_player_spawned(player : MultiplayerPlayer):
	var inventory_interface = player.find_child("InventoryInterface")
	inventory_interface.drop_slot_data.connect(_on_drop_slot_data)
	local_player = player

func _on_drop_slot_data(slot_data : InventorySlotPD):
	print(local_player.name)
	_rpc_on_drop.rpc(slot_data.inventory_item.resource_path, local_player.player_interaction_component.get_interaction_raycast_tip(local_player.find_child("Player_HUD").item_drop_distance_offset))



@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_drop(inventory_item_path : String, drop_position : Vector3):
	var inventory_item = load(inventory_item_path)
	print("Received Item Drop RPC: " + inventory_item.name)
	var scene_to_drop = load(inventory_item.drop_scene)
	Audio.play_sound(inventory_item.sound_drop)
	var dropped_item = scene_to_drop.instantiate()
	dropped_item.position = drop_position
	dropped_item.find_interaction_nodes()
	## Oh no, I need all the slot data too!
	#for node in dropped_item.interaction_nodes:
	#	if node.has_method("get_item_type"):
	#		node.slot_data = slot_data
	
	CogitoSceneManager._current_scene_root_node.add_child(dropped_item)
