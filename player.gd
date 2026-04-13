extends CharacterBody2D

# --- Character Scaling ---
# Amount to scale per step
@export var scale_step: float = 0.01
# Maximum allowed scale
@export var max_scale: float = 2.0

# This signal is emitted when the bird collides with something.
signal hit

# The upward force applied when the player "flaps".
const FLAP_FORCE = -425.0

# Get the project's gravity setting so we can apply it.
var gravity = 980 * 1.4

# We need a reference to the AnimatedSprite2D node.
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	# Start with the "fall" animation when the game begins.
	animated_sprite.play("flap")
	scale = Vector2.ONE
	
func _physics_process(delta):
	# Apply gravity every frame.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Check for the flap input.
	if Input.is_action_just_pressed("flap"):
		velocity.y = FLAP_FORCE
		# P"res://player.gd"lay the "flap" animation once.
		animated_sprite.play("flap")
		# Create a one-shot timer that will call a function after 0.25 seconds.
		# This is connected using a lambda function for a concise solution.
		get_tree().create_timer(0.25).timeout.connect(func(): animated_sprite.play("fall"))

	# Apply the bird's velocity. move_and_slide handles collisions.
	move_and_slide()

	# If a collision occurs, emit the "hit" signal.
	# The get_slide_collision_count() > 0 check is a reliable way to detect this.
	if get_slide_collision_count() > 0:
		hit.emit()
		
	# If the bird moves off-screen, delete it to free up memory.
	if position.y > 1000:
		hit.emit()

func increase_size():
	var new_scale = scale + Vector2.ONE * scale_step
	# Clamp to avoid infinite growth
	new_scale.x = clamp(new_scale.x, 0.1, max_scale)
	new_scale.y = clamp(new_scale.y, 0.1, max_scale)
	scale = new_scale
	
# This function disables the bird's physics process.
func stop():
	set_physics_process(false)
	
func end():
	animated_sprite.play('adult')
	set_physics_process(false)
