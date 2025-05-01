extends CharacterBody2D

func _physics_process(delta) -> void:
	$leomap.play("map")
