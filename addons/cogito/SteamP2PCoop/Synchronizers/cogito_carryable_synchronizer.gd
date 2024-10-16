class_name CogitoCarryableSynchronizer
extends Node

@export var level_spawner : MultiplayerLevelSpawner

## In seconds, how often the data should be sent for synced objects
@export var replication_interval : float = 0.1

var replication_timer : float = 0.0
var carryable_array
var currently_synced_objects = []


func _ready():
	level_spawner.level_loaded.connect(_on_multiplayer_level_spawner_level_loaded)


func _on_multiplayer_level_spawner_level_loaded():
	carryable_array = level_spawner.find_children("", "CogitoCarryableComponent", true, false)
	for carryable in carryable_array:
		carryable.carry_state_changed.connect(_on_carry_state_changed.bind(carryable))
		carryable.thrown.connect(_on_carryable_thrown.bind(carryable))


func _on_carry_state_changed(is_being_carried : bool, node : Node):
	_rpc_on_carry_state_changed.rpc(multiplayer.get_unique_id(), is_being_carried, carryable_array.find(node))

func _on_carryable_thrown(impulse, node : Node):
	## propogate the thrown force to all other users.
	## if they were just holding the object they should have multiplayer authority
	## this is to prevent recursive rpcs
	if node.get_parent().is_multiplayer_authority():
		_rpc_on_carryable_thrown.rpc(impulse, carryable_array.find(node))

@rpc("any_peer", "call_remote", "reliable")
func _rpc_on_carryable_thrown(impulse, carryable_index):
	var carryable = carryable_array[carryable_index]
	# TODO: Make a way to play this sound inside of the carryable
	## This is poor separation of concerns, but I did not want to push a play
	## sound function back to Cogito.
	if carryable.drop_sound:
		carryable.audio_stream_player_3d.stream = carryable.drop_sound
		carryable.audio_stream_player_3d.play()
	carryable.get_parent().apply_central_impulse(impulse)

@rpc("any_peer", "call_local", "reliable")
func _rpc_on_carry_state_changed(sender_id : int, is_being_carried : bool, carryable_index : int):
	if carryable_index == -1:
		printerr("CogitoCarryableSynchronizer: Received carry_state_changed RPC for node with id -1. 
				The node was not found in the array")
		return
	print ("received carry_state_changed RPC for carryable with id: %s" % carryable_index)
	
	## once a user picks this up the carry should be disabled for other players
	var carryable = carryable_array[carryable_index]
	carryable.is_disabled = is_being_carried
	
	if is_being_carried:
		## authority must be changed to the user who picked it up on all clients
		## the parent is the rigidbody of the carryable
		var carryable_parent = carryable.get_parent()
		carryable_parent.gravity_scale = 0.0
		print("setting multiplayer authority of %s to %s" % [carryable_parent.name, sender_id])
		carryable_parent.set_multiplayer_authority(sender_id)
		## add the index to the array of currently synced objects
		if currently_synced_objects.find(carryable_index) == -1:
			## only add if it is not already in the list
			currently_synced_objects.push_back(carryable_index)
	else:
		carryable.get_parent().gravity_scale = 1.0
		## remove the index from the array of currently synced objects
		currently_synced_objects.erase(carryable_index)

func _physics_process(delta):
	## timer for replication
	replication_timer += delta
	if replication_timer >= replication_interval:
		replication_timer -= replication_interval
	else: ## if timer is not met, abort syncing
		return
	
	## only the multiplayer authority of the carryable will send its position data to the others
	for synced_index in currently_synced_objects:
		## since we stored the synced objects by index, we need to go get the object
		## we want data from the rigidbody 3d, which is always the parent of the carryable
		var carryable_parent = carryable_array[synced_index].get_parent()
		if carryable_parent.is_multiplayer_authority():
			_rpc_sync_object.rpc(synced_index, carryable_parent.position, carryable_parent.rotation, carryable_parent.linear_velocity, carryable_parent.angular_velocity)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_sync_object(carryable_index : int, position : Vector3, rotation : Vector3, linear_velocity : Vector3, angular_velocity : Vector3):
	var rb = carryable_array[carryable_index].get_parent()
	rb.position = position
	rb.rotation = rotation
	rb.linear_velocity = linear_velocity
	rb.angular_velocity = angular_velocity
