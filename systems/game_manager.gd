extends Node

enum GameState {
    MENU,
    SPAWNING,
    CATCHING,
    STRUGGLING,
    RESULT
}

# Đổi sang SPAWNING để test dễ hơn
var state: GameState = GameState.SPAWNING

func set_state(new_state: GameState) -> void:
    if state == new_state:
        return
    state = new_state
    print("Game State changed to: ", state)
