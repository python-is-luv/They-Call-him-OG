extends Area2D
signal restart_level

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.queue_free()
		emit_signal("restart_level")
