extends CharacterBody2D

@export var speed: float = 200.0

var direction: float = 1.0
var screen_size: Vector2

func _ready() -> void:
    screen_size = get_viewport_rect().size
    direction = 1.0 if randf() > 0.5 else -1.0
    
    var margin = 100.0
    var spawn_y = randf_range(screen_size.y * 0.3, screen_size.y * 0.7)
    var spawn_x = -margin if direction == 1.0 else screen_size.x + margin
    
    global_position = Vector2(spawn_x, spawn_y)

func _physics_process(_delta: float) -> void:
    # Dừng chạy khi đang bị giữ lại (STRUGGLING)
    if GameManager.state == GameManager.GameState.STRUGGLING:
        velocity = Vector2.ZERO
    else:
        velocity.x = speed * direction
        move_and_slide()
    
    var margin = 150.0
    if (direction == 1.0 and global_position.x > screen_size.x + margin) or \
       (direction == -1.0 and global_position.x < -margin):
        queue_free()
