extends Node

@onready var leo = $leo
@onready var bird_scene: PackedScene = preload("res://cena/passaro.tscn")

var bird_heights := [200, 250]

#preload dos obstaculos
var tree_scene = preload("res://cena/arvore.tscn")
var rock_scene = preload("res://cena/pedra.tscn")
var serra_scene = preload("res://cena/serra.tscn")
var obstacle_types := [rock_scene, tree_scene]
var obstacles : Array
var serra_heights := [200, 350]
var ultimo_novo_objeto_spawn := 0  
const INTERVALO_NOVO_OBJETO := 2000

#variaveis
const LEO_START_POS := Vector2i(20, 230)
const CAM_START_POS := Vector2i(700, 365)
var difficulty
const MAX_DIFFICULTY : int = 2
var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var input_ready = false
var last_obs
const FINAL_POS := 30000  # Distância que define o fim do jogo
var game_finished : bool = false
var can_trigger_game_over := true

# Called when the node enters the scene tree for the first time.
func _ready():
	$MusicaFase.play()
	$GameOver.hide()
	add_to_group("passaro")
	screen_size = get_window().size
	ground_height = $chao.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	$GameOver.get_node("Button2").pressed.connect(voltar_para_mapa)
	$passou.get_node("Button2").pressed.connect(voltar_para_mapa)
	$leo.rotation_degrees = 0  # Coloca o Leo de volta na posição normal
	if not game_running and Input.is_action_just_pressed("atacar"):
		game_running = true
	$leo.perform_attack()  # Leo ataca ao iniciar
	randomize()
	spawn_bird()
	start_bird_timer()
	new_game()
	get_tree().paused = false
	input_ready = false
	await get_tree().create_timer(0.3).timeout
	input_ready = true
	
func voltar_para_mapa():
	get_tree().change_scene_to_file("res://cena/map.tscn")
	
func reset_progress_bar():
	var icon = $Hud/icon
	var bar = $Hud/progress
	icon.position.x = bar.position.x

func new_game():
	var anim_sprite = $leo.get_node("anim")
	if anim_sprite:
		anim_sprite.stop()
		anim_sprite.play("idle")
	game_running = false
	game_finished = false
	get_tree().paused = false
	difficulty = 0
	$leo.reset()
	if not game_running and Input.is_action_just_pressed("atacar"):
		game_running = true
	
	#deleta todos os obstaculos
	var obstacles_to_remove = []
	
	# Marcar obstáculos para remoção
	for obs in obstacles:
		if is_instance_valid(obs):
			if obs.has_signal("body_entered"):
				obs.body_entered.disconnect(hit_obs)
			obstacles_to_remove.append(obs)
	
	# Agora remove os obstáculos após o loop
	for obs in obstacles_to_remove:
		if is_instance_valid(obs):
			obs.queue_free()
	
	obstacles.clear()
	
	can_trigger_game_over = false
	await get_tree().create_timer(0.1).timeout  # Espera 0.1 segundos
	can_trigger_game_over = true

	# reseta os nodes
	$leo.position = LEO_START_POS
	$leo.velocity = Vector2.ZERO
	$leo.set_physics_process(true)  
	$Camera2D.position = CAM_START_POS
	$chao.position = Vector2i(0, 0)
	$leo.rotation_degrees = 0 
	
	#reset hud and game over screen
	$GameOver.visible = false
	$HUD.get_node("Start").show()
	$GameOver.hide()
	$passou.hide()
	
	reset_progress_bar()
	generate_obs()
	
func update_progress_bar():
	var icon = $Hud/icon
	var bar = $Hud/progress

	var bar_start = bar.position.x
	var bar_end = bar.position.x + 600
	
	var percent = clamp($leo.position.x / FINAL_POS, 0.0, 1.0)
	
	icon.position.x = lerp(bar_start, bar_end, percent)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running and not game_finished:
		update_progress_bar()
	if game_running:
		#sistema de velocidade e dificuldade
		speed = START_SPEED + $leo.position.x / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		#generate obstacles
		generate_obs()
		update_progress_bar()
		
		#movendo o leo e a camera
		$leo.position.x += speed
		$Camera2D.position.x += speed
		
		#da update no chão para que se repita
		if $Camera2D.position.x - $chao.position.x > screen_size.x * 1.5:
			$chao.position.x += screen_size.x
			
		#remove os obstaculos fora da tela
		var i = 0
		while i < obstacles.size():
			var obs = obstacles[i]
			if is_instance_valid(obs) and obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
			else:
				i += 1  # Só incrementa se não remover
				
	else:
		if not game_finished and input_ready and Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("Start").hide()
	if game_running and not game_finished:
		# sistema de velocidade e dificuldade
		speed = START_SPEED + $leo.position.x / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		# verifica se chegou ao final
		if $leo.position.x >= FINAL_POS:
			reach_finish_line()
			return  # Evita continuar processando esse frame
		
	if not game_finished and $leo.position.x >= FINAL_POS - 2800:
		var obstacles_copy = obstacles.duplicate()
		for obs in obstacles_copy:
			if is_instance_valid(obs):  # Verifica se o objeto ainda existe
				obs.queue_free()
		obstacles.clear()
		obstacle_types.clear()  # Impede que novos obstáculos sejam gerados
		
	if not can_trigger_game_over:
		can_trigger_game_over = true

func reach_finish_line():
	game_finished = true
	
	# Desativa a física do Leo
	$leo.velocity = Vector2i(0, 0)
	$leo.set_physics_process(false)
	
	# Posicionamento final
	$Camera2D.position.x = FINAL_POS + 300
	$leo.position.x = FINAL_POS + 200
	
	passaste()

func generate_obs():
	# gera os obstaculos no cenário
	if obstacle_types.is_empty():
		return
	if obstacles.is_empty() or last_obs == null or last_obs.position.x < $leo.position.x + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = max(1, int(difficulty + 1))  # Corrigido aqui
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + $leo.position.x + 100
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		#chance aleatoria de spawnas as aguias
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 1) == 0:
					obs = serra_scene.instantiate()
					var obs_x : int = screen_size.x + $leo.position.x + 100
					var obs_y : int = screen_size.y - ground_height - 400
					add_obs(obs, obs_x, obs_y)
					
func start_bird_timer():
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(spawn_bird)
	add_child(timer)
					
func spawn_bird():
	if not game_running:
		return 
	if (randi() % 2) == 0:
		var obs = bird_scene.instantiate()
		var obs_x = get_viewport().size.x + leo.position.x + 100
		var obs_y = bird_heights[randi() % bird_heights.size()]
		add_obs(obs, obs_x, obs_y)
					
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	if obs.has_signal("body_entered"):
		obs.body_entered.connect(hit_obs)
	if obs.has_node("Hitbox"):
		var hitbox = obs.get_node("Hitbox")
		if hitbox.has_signal("body_entered"):
			hitbox.body_entered.connect(_on_hitBox_body_entered)

	add_child(obs)
	obstacles.append(obs)
	
func _on_hitBox_body_entered(body):
	if body.name == "leo":
		if body.is_attacking:
			var parent = get_parent()
			if parent and parent.is_in_group("inimigos"):
				parent.queue_free()
		else:
			game_over()

func remove_obs(obs):
	if is_instance_valid(obs) and obs in obstacles:
		obs.queue_free()
		obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "leo" and can_trigger_game_over:
		game_over()
		
func adjust_difficulty():
	difficulty = $leo.position.x / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY
		
func game_over():
	if game_finished:
		return
	get_tree().paused = true
	game_running = false
	$GameOver.show()
	
func passaste():
	game_running = false
	
	$passou.show()
	
	# Toca a música de vitória apenas uma vez
	$MusicaFase.stop()
	$victory.stop() # Garante que não esteja tocando já
	$victory.play()
	
	$leo.get_node("anim").play("victory")
