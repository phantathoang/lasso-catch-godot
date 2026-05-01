extends Node

signal state_changed(new_state)
signal struggle_updated(current_force, max_force)
signal game_result(player_won)

enum GameState {
    MENU,
    SPAWNING,
    CATCHING,
    STRUGGLING,
    RESULT
}

var state: GameState = GameState.MENU

# Các biến cho cơ chế giằng co
var max_force: float = 100.0
var struggle_start_force: float = 40.0
var player_force: float = 0.0
var cow_force: float = 0.0
var player_increment: float = 5.0
var cow_pull_rate: float = 20.0

func _ready() -> void:
    # Bắt đầu vào SPAWNING để test vòng lặp
    call_deferred("set_state", GameState.SPAWNING)

func set_state(new_state: GameState) -> void:
    if state == new_state:
        return
        
    exit_state(state)
    state = new_state
    enter_state(state)
    
    state_changed.emit(state)

func enter_state(current_state: GameState) -> void:
    match current_state:
        GameState.STRUGGLING:
            # Khởi tạo lực với biến config struggle_start_force
            player_force = struggle_start_force
            cow_force = 0.0
            struggle_updated.emit(player_force - cow_force, max_force)
        GameState.RESULT:
            # Chờ 2s hiển thị kết quả rồi loop lại SPAWNING
            await get_tree().create_timer(2.0).timeout
            set_state(GameState.SPAWNING)

func exit_state(_current_state: GameState) -> void:
    pass

func _process(delta: float) -> void:
    # Bò tự kéo ngược khi giằng co
    if state == GameState.STRUGGLING:
        cow_force += cow_pull_rate * delta
        var current = player_force - cow_force
        
        struggle_updated.emit(current, max_force)
        
        # Check Win/Lose
        if current >= max_force:
            set_state(GameState.RESULT)
            game_result.emit(true)
        elif current <= 0:
            set_state(GameState.RESULT)
            game_result.emit(false)

func _unhandled_key_input(event: InputEvent) -> void:
    # Mash phím bắt kỳ (không phải nhấn giữ - echo)
    if state == GameState.STRUGGLING:
        if event is InputEventKey and event.is_pressed() and not event.is_echo():
            player_force += player_increment
            var current = player_force - cow_force
            struggle_updated.emit(current, max_force)
