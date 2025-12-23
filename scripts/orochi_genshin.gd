extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var sword_area = $SwordArea
@onready var hitbox = $Hitbox
@onready var damage_timer: Timer = $DamageTimer
var damage_source: Node = null
@export var max_health: int = 100
@export var current_health: int = 100

const BASE_SPEED = 200
var current_speed: float = BASE_SPEED
var is_attacking: bool = false
var can_take_damage: bool = true
var damage_cooldown: float = 0.5

signal health_depleted
signal health_changed(new_health: int)

func _ready() -> void:
	if has_node("HealthBar"):
		$HealthBar.max_value = max_health
		$HealthBar.value = current_health
	add_to_group("player")
	
	# Enable sword area only during attacks
	if sword_area:
		sword_area.monitoring = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()
		return
	
	if is_attacking:
		return
	
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = current_speed * direction
	move_and_slide()
	update_animation(direction)

func perform_attack() -> void:
	is_attacking = true
	
	var last_anim = anim.animation
	var direction_suffix = ""
	
	if "left" in last_anim:
		direction_suffix = "_left"
	elif "right" in last_anim:
		direction_suffix = "_right"
	elif "up" in last_anim:
		direction_suffix = "_up"
	else:
		direction_suffix = "_down"
	
	var attack_type = "attack" if randf() > 0.5 else "attack2"
	var attack_anim = attack_type + direction_suffix
	
	if sword_area:
		sword_area.monitoring = true
	
	anim.play(attack_anim)
	await anim.animation_finished
	
	if sword_area:
		sword_area.monitoring = false
	
	is_attacking = false

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		anim.play(get_idle_animation())
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim.play("run_right")
		else:
			anim.play("run_left")
	else:
		if direction.y > 0:
			anim.play("run_down")
		else:
			anim.play("run_up")

func get_idle_animation() -> String:
	var last_anim = anim.animation
	if "left" in last_anim:
		return "idle_left"
	elif "right" in last_anim:
		return "idle_right"
	elif "up" in last_anim:
		return "idle_up"
	else:
		return "idle_down"

func take_damage(damage: int) -> void:
	if not can_take_damage:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	if has_node("HealthBar"):
		$HealthBar.value = current_health
	
	health_changed.emit(current_health)
	
	# Flash effect
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()
		return
	
	# Invincibility frames
	can_take_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_take_damage = true

func die() -> void:
	health_depleted.emit()
	print("Player died!")
	queue_free()


func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("get_damage"):
			take_damage(body.get_damage())
		else:
			take_damage(10) # fallback damage
