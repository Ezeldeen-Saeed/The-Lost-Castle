extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var ray = $RayCast2D
@onready var ray2 = $RayCast2D2
@onready var death_audio = $deathAudio
@onready var hit_audio = $hitAudio

@onready var cooldown_timer = Timer.new()  # Timer for cooldown
@onready var death_timer = Timer.new()     # Timer for death animation

var health : int = 2
var speed : int = 20
var gravity : int = 2000
var distance : int = 200
var direction : int = -1
var start_position : Vector2

var attacking : bool = false
var can_attack : bool = true
var is_dead : bool = false

var death_animation_duration : float = 0.8  # Set this to the duration of your death animation

func _ready():
	start_position = position

	# Configure and add the cooldown timer to the node tree
	cooldown_timer.set_wait_time(2.0)  # Cooldown duration in seconds
	cooldown_timer.set_one_shot(true)
	add_child(cooldown_timer)
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_finished"))

	# Configure and add the death timer to the node tree
	death_timer.set_wait_time(death_animation_duration)
	death_timer.set_one_shot(true)
	death_timer.connect("timeout", Callable(self, "_queue_free_after_death"))
	add_child(death_timer)

func _physics_process(delta):

	if health <= 0:
		if not is_dead:
			_play_death_animation()
		return  # Stop further processing until the death animation is done

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Handle movement and animations
	if not attacking:
		# Move the enemy back and forth
		position.x += direction * speed * delta

		# Flip direction and update sprite
		if position.x >= start_position.x + distance:
			direction = -1
			sprite.flip_h = true
		elif position.x < start_position.x:
			direction = 1
			sprite.flip_h = false

		sprite.play("walk")  # Ensure walking animation plays when not attacking
	else:
		sprite.play("attack")

	# Check if either ray is colliding
	var collider = null
	if ray.is_colliding():
		collider = ray.get_collider()
	elif ray2.is_colliding():
		collider = ray2.get_collider()

	if collider and collider.is_in_group("players"):
		if collider.light.enabled:
			# Handle the enemy reaction when the light is on
			direction = -direction
			position.x += 50 + (direction * speed * delta)  # Move away from the player
		else:
			if can_attack:
				# Move towards the player
				if position.x < collider.position.x:
					direction = 1
					sprite.flip_h = false
				else:
					direction = -1
					sprite.flip_h = true

				# Update position
				position.x += direction * speed * delta

				# Check attack range
				if position.distance_to(collider.position) <= 30:  # Adjust distance for attack range
					# Attack the player if within range
					attacking = true
					collider.health -= 20
					print("Player health:", collider.health)
					
					# Start cooldown and disable attack until cooldown is done
					can_attack = false
					cooldown_timer.start()
				else:
					attacking = false  # Player is out of range, stop attacking
	else:
		attacking = false  # If no collider or player out of range, stop attacking

	move_and_slide()

func _on_cooldown_finished():
	hit_audio.playing = true
	can_attack = true  # Re-enable attack after cooldown is done

func _play_death_animation():
	if not is_dead:
		is_dead = true
		sprite.play("death")
		print("Death animation started")
		death_timer.start()
		print("Death timer started")

func _queue_free_after_death():
	print("Queue free called")
	death_audio.playing = true
	queue_free()
