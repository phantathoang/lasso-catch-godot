extends Node

enum GameState {
    MENU,
    SPAWNING,
    CATCHING,
    STRUGGLING,
    RESULT
}

var state: GameState = GameState.MENU

func set_state(new_state: GameState) -> void:
    if state == new_state:
        return
    state = new_state
    # Logic chuyển đổi state sẽ được xử lý sau
