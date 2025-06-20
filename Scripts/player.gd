extends CharacterBody3D

@onready var _camera_pivot := $CameraPivot as Node3D
@onready var _toilet_roll := $Visuals/ToiletRoll as Node3D

@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(60)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var mouse_captured := false

var is_moving := false
var is_moving_forward := false

var initial_camera_offset := Vector3.ZERO

func _ready():
	capture_mouse()

	# Speichere den ursprünglichen lokalen Offset der Kamera
	initial_camera_offset = _camera_pivot.position 
	# Setze die Kamera als Top-Level, damit sie nicht von Elterntransformationen beeinflusst wird
	_camera_pivot.top_level = true
	# Setze die anfängliche Position
	_camera_pivot.global_position = global_position + initial_camera_offset
	
func _physics_process(delta):
	_camera_pivot.global_position = global_position + initial_camera_offset

	if is_moving:
		rotation.y = _camera_pivot.rotation.y
		
		# Rotate toilet roll around world x axis
		if Input.is_action_pressed("forward"):
			_toilet_roll.rotate(Vector3(1, 0, 0), -delta * 2.0)
		elif Input.is_action_pressed("back"):
			_toilet_roll.rotate(Vector3(1, 0, 0), delta * 2.0)

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		is_moving = false
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		if other and other.is_in_group("enemies"):
			other.die()
			
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
	
func _on_area_body_entered(body):
	if body.is_in_group("EnemyPrefab"):
		print("yay")
