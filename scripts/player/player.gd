extends CharacterBody3D

# MOVEMENT VARIABLES

const MOVEMENT_SPEED = 150.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var movement_direction = Vector3.ZERO
var last_movement_direction = Vector3.ZERO
# ANIMATION VARIABLES
const SPRITESHEET_ROWS = 5 # animations
const SPRITESHEET_COLUMNS = 4 # frames per animation
const ANIMATION_SPEED = 0.046 /4

var anim_progress = 0
var animation_nr = 0
var is_walking = false

@onready var material = get_node("sprite").get_surface_override_material(0)
@onready var collision_box = get_node("collision")

func _physics_process(delta):
	var input_direction = Input.get_vector("pressed_right", "pressed_left", "pressed_up", "pressed_down")
	last_movement_direction = movement_direction
	movement_direction = Vector3(input_direction.y, 0, input_direction.x).normalized()
	movement_direction *= delta * MOVEMENT_SPEED
	
	update_position(delta)
	update_animation(delta)
	rotate_collision_box()
	
func update_position(delta):
	velocity.x = movement_direction.x
	velocity.z = movement_direction.z
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Handle Jump.
	#if Input.is_action_just_pressed("pressed_action") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	move_and_slide()
	
func get_anim_nr():

	# Make sure the animation is different then before when the direction changes
	if velocity.x != 0 && velocity.z != 0:
		if last_movement_direction != movement_direction:
			if velocity.x > 0:
				if velocity.z > 0:
					animation_nr = 0 if animation_nr == 2 else 2
				else:
					animation_nr = 0 if animation_nr == 1 else 1
			else:
				if velocity.z > 0:
					animation_nr = 3 if animation_nr == 2 else 2
				else:
					animation_nr = 3 if animation_nr == 1 else 1
	elif velocity.x != 0:
		animation_nr = 0 if velocity.x > velocity.z else 3
	elif velocity.z != 0:
		animation_nr = 1 if velocity.z < velocity.x else 2

	return animation_nr

func update_animation(delta):
	var sprite_x = get_anim_nr() / float(SPRITESHEET_COLUMNS)
	var sprite_y = 0
	
	if velocity != Vector3.ZERO:
		anim_progress += (MOVEMENT_SPEED * ANIMATION_SPEED * delta)
		anim_progress -= floor(anim_progress)
			
		is_walking = true
		var walking_frame = floor(anim_progress * float(SPRITESHEET_ROWS - 1)) + 1
		sprite_y = walking_frame / float(SPRITESHEET_ROWS)
	else: 
		anim_progress = 0
		is_walking = false

	material.uv1_offset = Vector3(sprite_x, sprite_y, 0)

func rotate_collision_box():
	if animation_nr == 0 || animation_nr == 3:
		collision_box.rotation = Vector3(0,0,0)
	elif animation_nr == 1 || animation_nr == 2:
		collision_box.rotation = Vector3(0,PI/2,0)
