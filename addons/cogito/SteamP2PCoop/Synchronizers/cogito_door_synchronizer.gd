class_name CogitoDoorSynchronizer
extends Node

@export var level_spawner : MultiplayerLevelSpawner

var door_array


func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	level_spawner.level_loaded.connect(_on_multiplayer_level_spawner_level_loaded)


func _on_multiplayer_level_spawner_level_loaded():
	door_array = level_spawner.find_children("", "CogitoDoor", true, false)
	for door in door_array:
		door.door_state_changed.connect(_on_door_state_changed.bind(door))
		door.lock_state_changed.connect(_on_lock_state_changed.bind(door))


func _on_door_state_changed(is_open : bool, node : Node):
	## index in array assures we will find the unique door
	## as long as all instances get the same order array
	_rpc_on_state_changed.rpc(is_open, door_array.find(node))

func _on_lock_state_changed(is_locked : bool, node : Node):
	_rpc_on_lock_state_changed.rpc(is_locked, door_array.find(node))

@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_state_changed(is_open : bool, door_index : int):
	if door_index == -1:
		printerr("CogitoDoorSynchronizer: Received switch RPC for node with id -1. 
				The node was not found in the array")
		return
	print ("received door RPC for door with id: %s" % door_index)
	_set_door_state(door_index, is_open)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_lock_state_changed(is_locked : bool, door_index : int):
	if door_index == -1:
		printerr("CogitoDoorSynchronizer: Received lock RPC for node with id -1. 
				The node was not found in the array")
		return
	print ("received door lock RPC for door with id: %s" % door_index)
	_set_lock_state(door_index, is_locked)

func _on_connected_to_server():
	_rpc_request_all_door_states.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_all_door_states():
	var door_state_array = []
	var lock_state_array = []
	for door in door_array:
		door_state_array.push_back(door.is_open)
		lock_state_array.push_back(door.is_locked)
	_rpc_receive_all_door_states.rpc(door_state_array)
	_rpc_receive_all_lock_states.rpc(lock_state_array)
	print("server received request for all door states")


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_all_door_states(state_array):
	for n in state_array.size():
		## prevent overflow
		if n < door_array.size():
			_set_door_state(n, state_array[n])
		else:
			printerr("CogitoDoorSynchronizer: Received state array 
					has more elements than door_array!")
	print("client received current door state data")

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_all_lock_states(state_array):
	for n in state_array.size():
		## prevent overflow
		if n < door_array.size():
			_set_lock_state(n, state_array[n])
		else:
			printerr("CogitoDoorSynchronizer: Received lock state array 
					has more elements than door_array!")
	print("client received current lock state data")

func _set_door_state(door_index : int, is_open : bool):
	if not door_array[door_index].is_open == is_open:
		if is_open:
			door_array[door_index].open_door(null)
		else:
			door_array[door_index].close_door(null)

func _set_lock_state(door_index : int, is_locked : bool):
	if not door_array[door_index].is_locked == is_locked:
		if is_locked:
			door_array[door_index].is_locked = true
		else:
			door_array[door_index].unlock_door()
