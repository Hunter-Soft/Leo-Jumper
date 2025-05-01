extends CharacterBody2D

var speed := 400

@onready var main_node = get_node("/root/Principal")
var bird_scene = preload("res://cena/passaro.tscn")

var dead: bool = false
var bird_heights := [200, 250]
var morreu = false

func _ready():
	add_to_group("inimigos")

func _process(delta):
	if dead:
		return
	position.x -= speed * delta
	if position.x < -100:
		queue_free()

func _on_hitbox_body_entered(body):
	if morreu:
		return
	if body.name == "leo":
		if body.is_attacking:
			morrer()
		else:
			body.morrer()  # Mata o Leo

func morrer():
	morreu = true
	$animaguia.play("die")  # Certifique-se de ter uma animação chamada "morte"
	$hitbox/CollisionShape2D2.call_deferred("set_disabled", true)  # Hitbox de dano

	# Desativar a área de detecção (hitbox)
	$hitbox.call_deferred("set_monitoring", false)
	$hitbox.call_deferred("set_monitorable", false) 

	await $animaguia.animation_finished
	queue_free()
