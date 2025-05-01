extends CharacterBody2D 

const GRAVITY_NORMAL : int = 4200
const GRAVITY_INVERTED : int = -4200
const JUMP_SPEED : int = -1600
const MOVE_SPEED : int = 300

var morreu = false
var velocidade_morte = Vector2(250, -300) # direção inicial
var gravidade = 900
var rotacao_velocidade = 10 # velocidade de rotação em rad/s

var gravity = GRAVITY_NORMAL
var can_flip_gravity = true  # Controle para impedir flipar toda hora
var is_attacking = false

func _physics_process(delta):
	# Impede ações do jogador enquanto o jogo não começou
	if not get_parent().game_running:
		velocity.x = 0
		$anim.play("idle")
		move_and_slide()
		return
		
	velocity.y += gravity * delta
	
	# Movimento lateral
	velocity.x = 0
	if Input.is_action_pressed("ui_left"):
		velocity.x = -MOVE_SPEED
	elif Input.is_action_pressed("ui_right"):
		velocity.x = MOVE_SPEED
		
	# Ataque
	if Input.is_action_just_pressed("atacar") and not is_attacking:
		is_attacking = true
		$anim.play("attack")
		perform_attack()

	# Verifica se a animação de ataque terminou
	if is_attacking and not $anim.is_playing():
		is_attacking = false
		if is_on_floor() or is_on_ceiling():
			$anim.play("run")
	
	# Pular e inverter gravidade
	if is_on_floor() or is_on_ceiling():
		can_flip_gravity = true  # Quando toca chão ou teto, pode flipar
		$colisao.disabled = false
		if Input.is_action_just_pressed("pular"):
			if gravity > 0:
				velocity.y = JUMP_SPEED
			else:
				velocity.y = -JUMP_SPEED
			$colisao.disabled = true
			$JumpSound.play()
			can_flip_gravity = true
	else:
		if Input.is_action_just_pressed("pular") and can_flip_gravity:
			$anim.play("double")
			gravity *= -1  # Inverte a gravidade
			can_flip_gravity = false
			$anim.scale.y *= -1  # Impede de inverter novamente no ar sem tocar o chão/teto
	
	# Animações
	if is_attacking:
		if not $anim.is_playing():
			is_attacking = false
	else:
		if is_on_floor() or is_on_ceiling():
			$anim.play("run")
		else:
			$anim.play("jump")
	
	move_and_slide()
	
func _ready():
	pass
	
func reset():
	morreu = false
	is_attacking = false
	can_flip_gravity = true
	gravity = GRAVITY_NORMAL
	position = Vector2i(20, 300)  # Substitua por uma posição válida inicial
	velocity = Vector2.ZERO
	$anim.scale.y = abs($anim.scale.y)  # Força escala positiva
	$anim.play("idle")  # Reinicia a animação
	
func perform_attack():
	is_attacking = true
	$anim.play("attack")

	$attackarea.monitoring = true
	$attackarea/CollisionShape2D.disabled = false

	await get_tree().create_timer(0.4).timeout
	$attackarea.monitoring = false
	$attackarea/CollisionShape2D.disabled = true
	is_attacking = false
	
func _on_attack_hit(body):
	if body.name == "passaro":
		body.morrer()  # A águia deve ter essa função
		
func morrer():
	if morreu:
		return
	morreu = true
	velocity = Vector2.ZERO
	# Se quiser rotação na morte:
	set_physics_process(false)  # Para parar de processar movimento se desejar
	get_parent().game_over()  # Chama a função de Game Over da cena principal, se ela existir
			
