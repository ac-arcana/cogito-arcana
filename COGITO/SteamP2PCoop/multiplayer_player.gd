extends CogitoPlayer
## Extend the player with multiplayer functionality

@export var sync_weight : float = 0.2

@export_group("Synced Vars")
## Exported so the Multiplayer Synchronizer can see the variable
@export var sync_position := Vector3.ZERO
## Exported so the Multiplayer Synchronizer can see the variable
@export var sync_rotation := Quaternion.IDENTITY
## Exported so the Multiplayer Synchronizer can see the variable
@export var sync_velocity := Vector3.ZERO

func _enter_tree():
	## when the game is starting single player mode we don't want to lose authority
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		set_multiplayer_authority(name.to_int())
	_disable_local_playermodel()
	
	#immediately remove the pause menu attached to the COGTIO Player we inherit
	find_child("PauseMenu").queue_free()
	
	#only the multiplayer authority's camera should be active
	if is_multiplayer_authority():
		find_child("Camera").make_current()
	else:
		#remove menu and HUD components if we are a client
		find_child("MultiplayerPauseMenu").queue_free()
		find_child("Player_HUD").queue_free()
		find_child("PlayerInteractionComponent").queue_free()
		#ensure this camera is disabled
		find_child("Camera").clear_current(true)


func _input(event):
	if not is_multiplayer_authority():
		return
	super(event)


func _physics_process(delta):
	if is_multiplayer_authority():
		super(delta)
		_owner_sync()
	else:
		_client_sync()

func _owner_sync():
	sync_position = global_position
	## get_rotation_quaternion prevents an error from sending basis as a quaternion.
	sync_rotation = body.global_basis.get_rotation_quaternion()
	sync_velocity = velocity

func _client_sync():
	global_position = global_position.lerp(sync_position, sync_weight)
	body.global_basis = body.global_basis.slerp(sync_rotation, sync_weight)
	print(body.global_rotation)
	velocity = sync_velocity
	move_and_slide()


func _disable_local_playermodel():
	var player_model = find_child("PlayerModel")
	if is_multiplayer_authority():
		player_model.visible = false
	else:
		player_model.visible = true
