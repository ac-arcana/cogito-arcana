class_name CogitoSwitchSynchronizer
extends Node

@export var level_spawner : MultiplayerLevelSpawner

var switch_array


func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	level_spawner.level_loaded.connect(_on_multiplayer_level_spawner_level_loaded)


func _on_multiplayer_level_spawner_level_loaded():
	switch_array = level_spawner.find_children("", "CogitoSwitch", true, false)
	for switch in switch_array:
		switch.switched.connect(_on_switch.bind(switch))


func _on_switch(is_on : bool, node : Node):
	## index in array assures we will find the unique switch
	## as long as all instances get the same order array
	_rpc_on_switch.rpc(is_on, switch_array.find(node))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_switch(is_on : bool, switch_index : int):
	if switch_index == -1:
		printerr("CogitoSwitchSynchronizer: Received switch RPC for node with id -1. 
				The node was not found in the array")
		return
	print ("received switch RPC for switch with id: %s" % switch_index)
	_set_switch(switch_index, is_on)


func _on_connected_to_server():
	_rpc_request_all_switch_states.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_all_switch_states():
	var state_array = []
	for switch in switch_array:
		state_array.push_back(switch.is_on)
	_rpc_receive_all_switch_states.rpc(state_array)
	print("server received request for all switch states")


@rpc("authority", "call_remote", "reliable")
func _rpc_receive_all_switch_states(state_array):
	for n in state_array.size():
		## prevent overflow
		if n < switch_array.size():
			_set_switch(n, state_array[n])
		else:
			printerr("CogitoSwitchSynchronizer: Received state array 
					has more elements than switch_array!")
	print("client received current switch state data")


func _set_switch(switch_index : int, is_on : bool):
	if not switch_array[switch_index].is_on == is_on:
		## just calling switch again results in recursive signals
		## calling the specific on or off functions will not play a sound effect
		## TODO: This is not good separation of concerns
		switch_array[switch_index].audio_stream_player_3d.play()
		if is_on:
			switch_array[switch_index].switch_on()
		else:
			switch_array[switch_index].switch_off()
