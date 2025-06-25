extends CharacterBody3D

@onready var _camera_pivot := $CameraPivot as Node3D
@onready var _toilet_roll := $Visuals/ToiletRoll as CSGCylinder3D

@export_range(0.0, 1.0) var mouse_sensitivity = 0.005
@export var tilt_limit = deg_to_rad(60)
@export var paper_distance = 1.0

const SPEED = 6.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1.8
const ROLL_ROTATION_SPEED = 2.0

var mouse_captured := false

var roll_percentage := 100.0

var main_scene = null
var paper_scene = null
var toilet_paper = null

var initial_camera_offset := Vector3.ZERO
var initial_roll_scale := 0.0
var last_paper_position := Vector3.ZERO

func _ready():
	capture_mouse()

	initial_roll_scale = _toilet_roll.radius

	paper_scene = load("res://Scenes/paper.tscn")
	main_scene = get_tree().current_scene

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
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(0, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Rotate toilet roll around world x axis
		if Input.is_action_pressed("forward"):
			_toilet_roll.rotate(Vector3(1, 0, 0), -delta * ROTATION_SPEED)
		elif Input.is_action_pressed("back"):
			_toilet_roll.rotate(Vector3(1, 0, 0), delta * ROTATION_SPEED)

		# Make paper trail if moving and on floor every 0.5 units
		if is_on_floor():
			roll_percentage -= delta * 10.0  # Decrease roll percentage over time
			roll_percentage = clamp(roll_percentage, 20, 100)

			# Scale the toilet roll based on the roll percentage
			var scale_factor = roll_percentage / 100.0
			_toilet_roll.radius = initial_roll_scale * scale_factor

			if roll_percentage <= 48:
				# Reset the roll when it runs out
				roll_percentage = 100.0
				_toilet_roll.radius = initial_roll_scale

			 # Calculate distance from last paper position
			var current_pos = Vector3(position.x, 0, position.z)  # Ignore Y for distance calculation
			var distance = current_pos.distance_to(Vector3(last_paper_position.x, 0, last_paper_position.z))
			
			# Only spawn paper if we've moved far enough
			if distance >= paper_distance:
				toilet_paper = paper_scene.instantiate()
				toilet_paper.position = Vector3(position.x, position.y-0.5, position.z)
				toilet_paper.rotation = Vector3(0, rotation.y, 0)
				main_scene.add_child(toilet_paper)
		
				# Update last paper position
				last_paper_position = position

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

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


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
