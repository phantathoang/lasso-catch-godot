extends Node2D

@export var cow_scene: PackedScene
@export var spawn_interval: float = 2.0

var timer: Timer

func _ready() -> void:
    # Sinh Timer động
    timer = Timer.new()
    timer.wait_time = spawn_interval
    timer.autostart = true
    timer.timeout.connect(_on_timer_timeout)
    add_child(timer)

func _on_timer_timeout() -> void:
    # Spawn bò theo thời gian, trong state phù hợp
    var valid_state = (GameManager.state == GameManager.GameState.SPAWNING or GameManager.state == GameManager.GameState.CATCHING)
    if valid_state and cow_scene:
        var cow_instance = cow_scene.instantiate()
        get_parent().add_child(cow_instance)
