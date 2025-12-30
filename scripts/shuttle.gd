extends CharacterBody2D
@export var speed = 300.0
@onready var animated_sprite = $AnimatedSprite2D
var is_destroyed := false

func _ready():
	animated_sprite.play("move")

func _physics_process(delta):
	if is_destroyed:
		return

	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	var viewport_rect = get_viewport_rect()
	position.x = clamp(position.x, 0, viewport_rect.size.x)
	position.y = clamp(position.y, 0, viewport_rect.size.y)

func on_hit():
	if is_destroyed:
		return

	is_destroyed = true
	velocity = Vector2.ZERO

	animated_sprite.play("destroy")
	animated_sprite.animation_finished.connect(_on_destroy_animation_finished)

func _on_destroy_animation_finished():
	get_tree().reload_current_scene()
