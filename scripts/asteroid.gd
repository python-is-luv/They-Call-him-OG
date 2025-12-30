extends Area2D

@export var fall_speed = 150.0
@export var asteroid_textures: Array[Texture2D] = []

func _ready():
	body_entered.connect(_on_body_entered)

	if asteroid_textures.size() > 0:
		var sprite = $Sprite2D
		sprite.texture = asteroid_textures[randi() % asteroid_textures.size()]

func _process(delta):
	position.y += fall_speed * delta
	
	if position.y > get_viewport_rect().size.y + 50:
		queue_free()

func _on_body_entered(body):
	if body.name == "Shuttle":
		if body.has_method("on_hit"):
			body.on_hit()
		queue_free()
