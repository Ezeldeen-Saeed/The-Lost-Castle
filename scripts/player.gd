extends CharacterBody2D

# Movement variables
var speed : int = 200
var jump_force : int = -350
var gravity : int = 2000

var health : int = 100
var is_dead : bool = false
var has_key : bool = false
var on_door : bool = false
var last_door : bool = false
var key_door_opened : bool = false
var torsh_pick_area = false
var key_pick_area = false
var is_attacking = false
var attack_cooldown : float = 0.5
var attack_timer = Timer.new()

@onready var GameOver = %GameOver
@onready var win = %Win

@onready var sprite = $AnimatedSprite2D
@onready var light = $PointLight2D2
@onready var lighting_timer = $LightingTimer
@onready var pickedTorsh = $"res://scenes/Torsh_Pickup.tscn"
@onready var ray2 = $RayCast2D2
@onready var ray = $RayCast2D
@onready var key_image = $KeyImage
@onready var pickedKey = $"res://scenes/Key.tscn"
@onready var hitAudio = $hitAudio
@onready var torshAudio = $torshAudio
@onready var keyAudio = $keyAudio
@onready var door_audio = $doorAudio
@onready var overAudio = $overAudio
@onready var label = $Label


@onready var death_timer = Timer.new()

var death_animation_duration : float = 1.0
var next_door_position : Vector2 = Vector2(-371.0, -96.1)

func _ready():
	light.enabled = false
	sprite.play("idle")

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	add_child(attack_timer)

	# Check before connecting the signal
	if not attack_timer.is_connected("timeout", Callable(self, "_end_attack")):
		attack_timer.connect("timeout", Callable(self, "_end_attack"))

	death_timer.wait_time = death_animation_duration
	death_timer.one_shot = true
	
	# Check before connecting the signal
	if not death_timer.is_connected("timeout", Callable(self, "_queue_free_after_death")):
		death_timer.connect("timeout", Callable(self, "_queue_free_after_death"))
	add_child(death_timer)

func _physics_process(delta):
	label.text = "HEALTH: " + str(health)
	
	if has_key:
		key_image.visible = true
	else:
		key_image.visible = false
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = 0
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed
		sprite.flip_h = false
		if not is_attacking:
			sprite.play("walk")
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -speed
		sprite.flip_h = true
		if not is_attacking:
			sprite.play("walk")
	else:
		if is_on_floor() and not is_attacking:
			sprite.play("idle")

	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_force
		if not is_attacking:
			sprite.play("jump")
	
	if Input.is_action_pressed("ui_open"):
		if last_door:
			win.visible = true
			queue_free()
			return
			door_audio.playing = true
		if on_door and !key_door_opened:
			if has_key:
				print("door opened!!!")
				var temp = Vector2(0.0, 0.0)
				temp = position
				position = next_door_position
				next_door_position = temp
				has_key = false
				key_image.visible = false
				key_door_opened = true
				door_audio.playing = true
		elif on_door and key_door_opened:
			print("door opened!!!")
			var temp = Vector2(0.0, 0.0)
			temp = position
			position = next_door_position
			next_door_position = temp
			door_audio.playing = true

	move_and_slide()

	if Input.is_action_just_pressed("ui_attack") and not attack_timer.is_stopped() == false:
		attack()
		hitAudio.playing = true

	if Input.is_action_just_pressed("ui_pick"):
		if torsh_pick_area:
			pick_torsh()
		elif key_pick_area:
			pick_key()

	if health <= 0:
		if not is_dead:
			_play_death_animation()
		return

func attack():
	is_attacking = true
	sprite.play("hit")

	var collider = null
	if ray.is_colliding():
		collider = ray.get_collider()
	elif ray2.is_colliding():
		collider = ray2.get_collider()

	if collider and collider.is_in_group("enemies"):
		if collider.has_method("apply_damage"):
			collider.apply_damage(1)
		else:
			collider.health -= 1

	attack_timer.start()

	# Check if the signal is already connected before connecting
	if not attack_timer.is_connected("timeout", Callable(self, "_end_attack")):
		attack_timer.connect("timeout", Callable(self, "_end_attack"))

func _end_attack():
	is_attacking = false
	sprite.play("idle")

func pick_torsh():
	print("pressed")
	light.enabled = true
	lighting_timer.start()
	torshAudio.playing = true

	if pickedTorsh != null:
		pickedTorsh.queue_free()
		pickedTorsh = null

func pick_key():
	print("pressed")
	has_key = true
	key_image.visible = true
	keyAudio.playing = true

	if pickedKey != null:
		pickedKey.queue_free()
		pickedKey = null

func _on_lighting_timer_timeout():
	light.enabled = false

func _on_area_2d_area_entered(area):
	print("entered")
	if area.is_in_group("torshPicks"):
		torsh_pick_area = true
		pickedTorsh = area
	elif area.is_in_group("keys"):
		key_pick_area = true
		pickedKey = area
	else:
		print("on the door")
		if area.last_door:
			last_door = true
		on_door = true

func _on_area_2d_area_exited(area):
	if area.is_in_group("torshPicks"):
		torsh_pick_area = false
		pickedTorsh = null
	elif area.is_in_group("keys"):
		key_pick_area = false
		pickedKey = null
	else:
		on_door = false

func _play_death_animation():
	if not is_dead:
		is_dead = true
		sprite.play("death")
		print("Death animation started")
		death_timer.start()
		print("Death timer started")

func _queue_free_after_death():
	print("Queue free called")
	queue_free()
	GameOver.visible = true
	overAudio.playing = true
