extends CharacterBody3D

@onready var _camera_pivot := $CameraPivot as Node3D
@onready var _toilet_roll := $Visuals/ToiletRoll as CSGCylinder3D
@onready var _player_model: = $Visuals/PlayerModel  as Node3D
@onready var _player_sounds: = $SoundManagerPlayer  as Node3D

@export_range(0.0, 1.0) var mouse_sensitivity = 0.005
@export var tilt_limit = deg_to_rad(60)
@export var paper_distance = 1.0

const SPEED = 6.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1.8
const ROLL_ROTATION_SPEED = 2.0

var mouse_captured := false

var main_scene = null
var paper_scene = null
var toilet_paper = null

var initial_camera_offset := Vector3.ZERO
var initial_roll_scale := 0.0
var last_paper_position := Vector3.ZERO

var locomotion_blend_path : String = "parameters/blend_position"  
var input_cur : Vector2 = Vector2(0, 0)  
var input_acc : float = 0.1  
var player_anim_tree : AnimationTree
var player_anim_player : AnimationPlayer

var sounds_fegen : AudioStreamPlayer3D
var sounds_jump : AudioStreamPlayer3D

var hud : CanvasLayer

var health : int = 3
var heart_nodes
var can_move : bool = true

func _ready():
	$BodyArea.body_entered.connect(_on_player_body_entered)
	$RollArea.body_entered.connect(_on_roll_body_entered)
	$RollArea.area_entered.connect(_on_roll_area_entered)

	hud = get_tree().get_root().get_node("Main/HUD")
	heart_nodes = hud.get_node("Hearts").get_children()

	player_anim_tree = _player_model.get_node("AnimationTree")
	player_anim_player = _player_model.get_node("AnimationPlayer")

	capture_mouse()

	initial_roll_scale = _toilet_roll.radius

	paper_scene = load("res://Scenes/paper.tscn")
	main_scene = get_tree().current_scene

	sounds_fegen = _player_sounds.get_node("Fegen")
	sounds_jump = _player_sounds.get_node("Jump")

	# Speichere den ursprünglichen lokalen Offset der Kamera
	initial_camera_offset = _camera_pivot.position 
	# Setze die Kamera als Top-Level, damit sie nicht von Elterntransformationen beeinflusst wird
	_camera_pivot.top_level = true
	# Setze die anfängliche Position
	_camera_pivot.global_position = global_position + initial_camera_offset


func _physics_process(delta):
	_camera_pivot.global_position = global_position + initial_camera_offset

	# Handle Left/Right rotation.
	if Input.is_action_pressed("left"):
		rotation.y += ROTATION_SPEED * delta
	elif Input.is_action_pressed("right"):
		rotation.y -= ROTATION_SPEED * delta

	# Add the gravity.
	if not is_on_floor():
		sounds_fegen.stop()
		velocity += get_gravity() * delta
		if position.y < -100.0:
			position = get_tree().get_root().get_node("Main/RespawnPosition").position
	else:
		player_anim_tree.active = true

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		player_anim_tree.active = false
		player_anim_player.play("jump")
		sounds_jump.play()

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(0, 0, input_dir.y)).normalized()

	input_cur += (Vector2(0, input_dir.y) - input_cur).clamp(Vector2(-input_acc, -input_acc), Vector2(input_acc, input_acc))  
	player_anim_tree.set(locomotion_blend_path, input_cur)  

	if direction and can_move:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Rotate toilet roll around world x axis
		if Input.is_action_pressed("forward"):
			_toilet_roll.rotate(Vector3(1, 0, 0), -delta * ROTATION_SPEED)
		elif Input.is_action_pressed("back"):
			_toilet_roll.rotate(Vector3(1, 0, 0), delta * ROTATION_SPEED)

		# Make paper trail if moving and on floor every 0.5 units
		if is_on_floor():
			if not sounds_fegen.playing:
				sounds_fegen.play()
			# Calculate distance from last paper position
			var current_pos = Vector3(position.x, 0, position.z)  # Ignore Y for distance calculation
			var distance = current_pos.distance_to(Vector3(last_paper_position.x, 0, last_paper_position.z))
			
			# Only spawn paper if we've moved far enough
			if distance >= paper_distance:
				toilet_paper = paper_scene.instantiate()
				toilet_paper.position = Vector3(position.x, position.y-0.7, position.z)
				toilet_paper.rotation = Vector3(0, rotation.y, 0)
				toilet_paper.add_to_group("papers")
				main_scene.add_child(toilet_paper)
		
				# Update last paper position
				last_paper_position = position

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		sounds_fegen.stop()

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)

		_camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity

	# Toggle mouse capture with Escape key
	if Input.is_action_just_pressed("pause"):
		if mouse_captured:
			release_mouse()
		else:
			capture_mouse()


func take_damage():
	health = health - 1
	for i in range(heart_nodes.size()):
		if i == health:
			heart_nodes[i].visible = false
	if health == 0:
		respawn(true)



func _on_player_body_entered(body):
	if body and body.is_in_group("enemies"):
		take_damage()
		body.die()
		
func _on_roll_body_entered(body):
	if body and body.is_in_group("enemies"):
		body.die()

func _on_roll_area_entered(area):
	if area.name == "GoalArea":
		respawn(false)


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func respawn(is_dying):
	if (is_dying):
		can_move = false
		hud.get_node("DeathScreen").visible = true
	else:
		hud.get_node("WinScreen").visible = true

	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for p in get_tree().get_nodes_in_group("papers"):
		p.queue_free()

	await get_tree().create_timer(5.0).timeout

	hud.get_node("WinScreen").visible = false
	hud.get_node("DeathScreen").visible = false
	position = get_tree().get_root().get_node("Main/RespawnPosition").position

	can_move = true

	health = 3
	for i in range(heart_nodes.size()):
		heart_nodes[i].visible = true
