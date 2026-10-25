class_name CollectibleItem
extends Area2D

signal collected(heal_amount: int, bonus_score: int)

var heal_amount: int = 20
var bonus_score: int = 50
var animated_sprite: AnimatedSprite2D
var time_alive: float = 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2

	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 12.0
	shape_node.shape = circle
	add_child(shape_node)

	animated_sprite = AnimatedSprite2D.new()
	var frames: SpriteFrames = SpriteFrames.new()
	var tex: Texture2D = load("res://assets/sprites/pickup_sheet.png")

	var f0: AtlasTexture = AtlasTexture.new()
	f0.atlas = tex
	f0.region = Rect2(0, 0, 32, 32)

	var f1: AtlasTexture = AtlasTexture.new()
	f1.atlas = tex
	f1.region = Rect2(32, 0, 32, 32)

	if not frames.has_animation("pulse"):
		frames.add_animation("pulse")
	frames.set_animation_loop("pulse", true)
	frames.set_animation_speed("pulse", 4.0)
	frames.add_frame("pulse", f0)
	frames.add_frame("pulse", f1)

	animated_sprite.sprite_frames = frames
	animated_sprite.play("pulse")
	add_child(animated_sprite)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_alive += delta
	if animated_sprite != null:
		animated_sprite.position.y = sin(time_alive * 5.0) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		var player: PlayerController = body as PlayerController
		player.heal(heal_amount)
		collected.emit(heal_amount, bonus_score)
		queue_free()
