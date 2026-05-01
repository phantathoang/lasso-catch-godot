extends CharacterBody2D

@export var max_distance: float = 400.0
@export var throw_speed: float = 800.0

@onready var hand: Marker2D = $Hand
@onready var lasso: Line2D = $Lasso
@onready var lasso_head: Area2D = $LassoHead

var is_throwing: bool = false

func _ready() -> void:
	lasso_head.position = hand.position
	# Lắng nghe va chạm của LassoHead với Bò (body_entered vì bò là CharacterBody2D)
	lasso_head.body_entered.connect(_on_lasso_head_body_entered)

func _unhandled_input(event: InputEvent) -> void:
	# Input click chuột trái
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var valid_state = (GameManager.state == GameManager.GameState.SPAWNING or GameManager.state == GameManager.GameState.CATCHING)
		if not is_throwing and valid_state:
			throw_lasso(get_global_mouse_position())

func throw_lasso(target_global_pos: Vector2) -> void:
	is_throwing = true
	
	# Tính hướng và giới hạn khoảng cách
	var throw_dir = (target_global_pos - hand.global_position).normalized()
	var distance = min(hand.global_position.distance_to(target_global_pos), max_distance)
	var final_target = hand.global_position + throw_dir * distance
	
	var duration = distance / throw_speed
	
	# Tween LassoHead tới target (Ease-Out)
	var tween = create_tween()
	tween.tween_property(lasso_head, "global_position", final_target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(return_lasso)

func return_lasso() -> void:
	# Tween quay về Hand (Ease-In)
	var distance = lasso_head.global_position.distance_to(hand.global_position)
	var duration = distance / (throw_speed * 1.5) # Thu về nhanh hơn
	
	var tween = create_tween()
	tween.tween_property(lasso_head, "global_position", hand.global_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_throwing = false)

func _process(_delta: float) -> void:
	# Cập nhật Line2D liên tục
	lasso.clear_points()
	lasso.add_point(hand.position)
	lasso.add_point(lasso_head.position)

func _on_lasso_head_body_entered(body: Node2D) -> void:
	if body.name.begins_with("Cow"):
		print("Lasso caught a cow!")
		GameManager.set_state(GameManager.GameState.STRUGGLING)
		lasso_head.get_node("CollisionShape2D").set_deferred("disabled", true)
		return_lasso() # Thu dây về ngay khi trúng
