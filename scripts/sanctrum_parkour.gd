extends Node2D

func _ready():
	$DieZone.restart_level.connect(_on_restart_level)

func _on_restart_level() -> void:
	get_tree().reload_current_scene()
