extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox: Area2D = $Hitbox
@onready var regen_timer: Timer = $RegenTimer
@onready var damage_timer: Timer = $DamageTimer
var damage_source: Node = null
var position_history: Array[Vector2] = []
const MAX_HISTORY = 10

@export var max_health: int = 100
@export var current_health: int = 100

const SPEED := 200.0
const JUMP_FORCE := -450.0
const GRAVITY := 1000.0
var can_air_jump := true
var is_attacking := false
var can_take_damage := true
var damage_cooldown := 0.5
var facing_right := true

signal health_depleted
signal health_changed(new_health: int)

func _ready() -> void:
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_to_group("player")

	if has_node("HealthBar"):
		$HealthBar.max_value = max_health
		$HealthBar.value = current_health

	if sword_area:
		sword_area.monitoring = false

	regen_timer.timeout.connect(_on_regen_timer_timeout)
	regen_timer.start()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

	if is_attacking:
		move_and_slide()
		return

	handle_jump()
	handle_attack()
	handle_movement()

	move_and_slide()
	position_history.insert(0, global_position)
	if position_history.size() > MAX_HISTORY:
		position_history.pop_back()
	update_animation()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
		can_air_jump = true

func handle_movement() -> void:
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * SPEED

	if direction != 0:
		facing_right = direction > 0
		anim.flip_h = not facing_right

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	elif Input.is_action_just_pressed("jump") \
	and Input.is_key_pressed(KEY_SHIFT) \
	and not is_on_floor() \
	and can_air_jump:
		velocity.y = JUMP_FORCE
		can_air_jump = false

func handle_attack() -> void:
	if is_attacking:
		return

	if Input.is_action_just_pressed("attack") and is_on_floor():
		start_attack()

func start_attack() -> void:
	is_attacking = true
	velocity.x = 0

	var attack_anim := "attack1" if randf() > 0.5 else "attack2"

	if sword_area:
		sword_area.monitoring = true

	anim.play(attack_anim)
	anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	if sword_area:
		sword_area.monitoring = false

	is_attacking = false

func update_animation() -> void:
	if is_attacking:
		return

	if not is_on_floor():
		anim.play("idle")
		return

	if abs(velocity.x) > 1:
		anim.play("run")
	else:
		anim.play("idle")

func take_damage(damage: int) -> void:
	if not can_take_damage:
		return

	regen_timer.stop()
	regen_timer.start()

	current_health = max(current_health - damage, 0)

	if has_node("HealthBar"):
		$HealthBar.value = current_health

	health_changed.emit(current_health)

	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if current_health <= 0:
		die()
		return

	can_take_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_take_damage = true

func die() -> void:
	health_depleted.emit()
	queue_free()

func _on_regen_timer_timeout() -> void:
	if can_take_damage and current_health > 0:
		current_health = min(current_health + 5, max_health)

		if has_node("HealthBar"):
			$HealthBar.value = current_health

		health_changed.emit(current_health)
		
func start_damage_from(enemy: Node, damage: int) -> void:
	if damage_timer.is_stopped():
		damage_source = enemy
		damage_timer.start()

func stop_damage_from(enemy: Node) -> void:
	if damage_source == enemy:
		damage_source = null
		damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	if damage_source and damage_source.has_method("get_damage"):
		take_damage(damage_source.get_damage())

func get_damage() -> int:
	return 0
	
func is_dead() -> bool:
	return false
	
func _draw() -> void:
	if position_history.size() > 1:
		for i in range(position_history.size() - 1):
			draw_line(position_history[i] - global_position, 
					  position_history[i+1] - global_position, 
					  Color.CYAN, 2.0)

func _process(_delta):
	queue_redraw()
