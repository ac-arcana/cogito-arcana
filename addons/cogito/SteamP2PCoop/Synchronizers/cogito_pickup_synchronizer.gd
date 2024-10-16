class_name CogitoPickupSynchronizer
extends Node

@export var level_spawner : MultiplayerLevelSpawner

var pickup_array


func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	level_spawner.level_loaded.connect(_on_multiplayer_level_spawner_level_loaded)


func _on_multiplayer_level_spawner_level_loaded():
	pickup_array = level_spawner.find_children("", "CogitoPickupComponent", true, false)
	for pickup in pickup_array:
		pickup.was_interacted_with.connect(_on_pickup.bind(pickup))


func _on_pickup(interaction_text, input_map_action, node : Node):
	_rpc_on_pickup.rpc(pickup_array.find(node))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_pickup(pickup_index : int):
	if pickup_index == -1:
		printerr("CogitoPickupSynchronizer: Received pickup RPC for node with id -1. 
				The node was not found in the array")
		return
	print ("received pickup RPC for pickup with id: %s" % pickup_index)
	_pickup(pickup_index)


func _on_connected_to_server():
	_rpc_request_all_pickup_states.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_all_pickup_states():
	var state_array = []
	for pickup in pickup_array:
		if is_instance_valid(pickup):
			#true if it has not been picked up
			state_array.push_back(true)
		else:
			print("found item that was already picked up")
			#invalid instances are freed - already picked up
			#set to false if it has been picked up
			state_array.push_back(false)
	_rpc_receive_all_pickup_states.rpc(state_array)
	print("server received request for all pickup states")


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_all_pickup_states(state_array):
	for n in state_array.size():
		## prevent overflow
		if n < state_array.size():
			if not state_array[n]:
				print("received a picked up item id")
				#not would be the item has been picked up already
				_pickup(n)
		else:
			printerr("CogitoPickupSynchronizer: Received state array 
					has more elements than pickup_array!")
	print("client received current pickup state data")


func _pickup(pickup_index : int):
	var pickup = pickup_array[pickup_index]
	if not pickup: # sanity check
		return
	#TODO: this is not good separation of concerns...
	Audio.play_sound(pickup.slot_data.inventory_item.sound_pickup)
	pickup.get_parent().queue_free()
	
