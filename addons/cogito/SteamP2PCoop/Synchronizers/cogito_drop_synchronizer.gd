class_name CogitoDropSynchronizer
extends Node

## This slot data does not need to contain any information
## It is simply an instance, so that we can use it to spoof information from dropped items
@export var dummy_slot : InventorySlotPD

var local_player : MultiplayerPlayer
var player_hud : CogitoPlayerHudManager

#TODO handle synchronization when a new player joins after an item has been dropped.

#gets a signal from the multiplayer_player_spawner
func _on_multiplayer_player_spawner_local_player_spawned(player : MultiplayerPlayer):
	var inventory_interface = player.find_child("InventoryInterface")
	inventory_interface.drop_slot_data.connect(_on_drop_slot_data)
	local_player = player
	player_hud = local_player.find_child("Player_HUD")

func _on_drop_slot_data(slot_data : InventorySlotPD):
	var quantity : int = 0
	if slot_data.inventory_item is WieldableItemPD:
		quantity = slot_data.inventory_item.charge_current
	elif slot_data.inventory_item is InventoryItemPD:
		quantity = slot_data.inventory_item.quantity
	_rpc_on_drop.rpc(slot_data.inventory_item.resource_path, slot_data.quantity, quantity, slot_data.MAX_STACK_SIZE, slot_data.origin_index, local_player.player_interaction_component.get_interaction_raycast_tip(player_hud.item_drop_distance_offset))



@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_drop(inventory_item_path : String, slot_quantity : int, item_quantity : int, max_stack_size : int, origin_index : int, drop_position : Vector3):
	var inventory_item = load(inventory_item_path)
	## Duplicate to prevent overwriting quantity of item in other player's scenes
	inventory_item = inventory_item.duplicate()
	if inventory_item is WieldableItemPD:
		inventory_item.charge_current = item_quantity
	elif inventory_item is InventoryItemPD:
		inventory_item.quantity = item_quantity
	print("Received Item Drop RPC: " + inventory_item.name)
	
	## set up the slot data
	var slot_data : InventorySlotPD = dummy_slot.duplicate()
	slot_data.inventory_item = inventory_item
	slot_data.quantity = slot_quantity
	slot_data.origin_index = origin_index
	
	var scene_to_drop = load(inventory_item.drop_scene)
	Audio.play_sound(inventory_item.sound_drop)
	var dropped_item = scene_to_drop.instantiate()
	dropped_item.position = drop_position

	# TODO send a signal to pickup synchronizer so the dropped item is added and synced
	dropped_item.find_interaction_nodes()
	for node in dropped_item.interaction_nodes:
		if node.has_method("get_item_type"):
			node.slot_data = slot_data
	
	CogitoSceneManager._current_scene_root_node.add_child(dropped_item)
