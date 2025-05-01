extends Node2D

var posicoes = [
	Vector2(215, 112),   # Círculo de cima
	Vector2(215, 210)   # Círculo de baixo
]
var indice = 0
var em_movimento = false
var velocidade = 100.0  # pixels por segundo

@onready var leo = $leomap

func _ready():
	get_tree().paused = false
	leo.position = posicoes[indice]
	$MusicaMapa.play()
	

func _process(delta):
	if em_movimento:
		var destino = posicoes[indice]
		var direcao = (destino - leo.position).normalized()
		leo.position += direcao * velocidade * delta

		if leo.position.distance_to(destino) < 2:
			leo.position = destino
			em_movimento = false

	else:
		if Input.is_action_just_pressed("ui_down") and indice < posicoes.size() - 1:
			indice += 1
			em_movimento = true
		elif Input.is_action_just_pressed("ui_up") and indice > 0:
			indice -= 1
			em_movimento = true
