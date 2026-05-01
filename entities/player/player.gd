extends CharacterBody2D

@export var max_distance: float = 400.0
@export var throw_speed: float = 800.0

@onready var hand: Marker2D = $Hand
@onready var lasso: Line2D = $Lasso
@onready var lasso_head: Area2D = $LassoHead

var is_throwing: bool = false
var caught_cow: Node2D = null

func _ready() -> void:
	lasso_head.position = hand.position
	lasso_head.body_entered.connect(_on_lasso_head_body_entered)
	GameManager.game_result.connect(_on_game_result)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var valid_state = (GameManager.state == GameManager.GameState.SPAWNING or GameManager.state == GameManager.GameState.CATCHING)
		if not is_throwing and valid_state:
			throw_lasso(get_global_mouse_position())

func throw_lasso(target_global_pos: Vector2) -> void:
	is_throwing = true
	var throw_dir = (target_global_pos - hand.global_position).normalized()
	var distance = min(hand.global_position.distance_to(target_global_pos), max_distance)
	var final_target = hand.global_position + throw_dir * distance
	var duration = distance / throw_speed
	
	var tween = create_tween()
	tween.tween_property(lasso_head, "global_position", final_target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(return_lasso)

func return_lasso() -> void:
	# Tạm giữ dây nếu đang giằng co
	if GameManager.state == GameManager.GameState.STRUGGLING:
		return
		
	var distance = lasso_head.global_position.distance_to(hand.global_position)
	var duration = distance / (throw_speed * 1.5)
	
	var tween = create_tween()
	tween.tween_property(lasso_head, "global_position", hand.global_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_throwing = false)

func _process(_delta: float) -> void:
	# Đầu dây bám theo bò khi đang giằng co
	if GameManager.state == GameManager.GameState.STRUGGLING and is_instance_valid(caught_cow):
		lasso_head.global_position = caught_cow.global_position
		
	lasso.clear_points()
	lasso.add_point(hand.position)
	lasso.add_point(lasso_head.position)

func _on_lasso_head_body_entered(body: Node2D) -> void:
	# Va chạm bò -> Bắt đầu giằng co
	if body.name.begins_with("Cow") and GameManager.state in [GameManager.GameState.SPAWNING, GameManager.GameState.CATCHING]:
		caught_cow = body
		lasso_head.get_node("CollisionShape2D").set_deferred("disabled", true)
		GameManager.set_state(GameManager.GameState.STRUGGLING)

func _on_game_result(player_won: bool) -> void:
	if is_instance_valid(caught_cow):
		if player_won:
			caught_cow.queue_free() # Player thắng thì bò biến mất
	
	caught_cow = null
	lasso_head.get_node("CollisionShape2D").set_deferred("disabled", false)
	return_lasso() # Thu dây về
