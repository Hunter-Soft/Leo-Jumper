extends Area2D

@export var max_obs = 5
@export var tree_scene: PackedScene
@export var rock_scene: PackedScene
@export var bird_scene: PackedScene
@export var serra_scene: PackedScene

func _ready():
	var obs_list = [tree_scene, rock_scene, bird_scene, serra_scene]
	for i in range(randi() % int(max_obs) + 1):
		var obs_type = obs_list[randi() % obs_list.size()]
		if obs_type:
			var obs = obs_type.instantiate()
			add_child(obs)

var entered = false

func _on_body_entered(body: PhysicsBody2D):
	entered = true


func _on_body_exited(body):
	entered = false
	
func _physics_process(delta):
	if entered == true:
		if Input.is_action_just_pressed("ui_accept"):
			print("sendo apertado")
			get_tree().change_scene_to_file("res://cena/principal.tscn")
