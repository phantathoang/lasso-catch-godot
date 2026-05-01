extends CanvasLayer

@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var struggle_bar: ProgressBar = $VBoxContainer/StruggleBar

func _ready() -> void:
    # Đăng ký lắng nghe tín hiệu
    GameManager.state_changed.connect(_on_state_changed)
    GameManager.struggle_updated.connect(_on_struggle_updated)
    GameManager.game_result.connect(_on_game_result)
    
    struggle_bar.visible = false
    hint_label.text = "Catch a cow!"

func _on_state_changed(new_state) -> void:
    match new_state:
        GameManager.GameState.SPAWNING, GameManager.GameState.CATCHING:
            hint_label.text = "Click to throw Lasso!"
            struggle_bar.visible = false
        GameManager.GameState.STRUGGLING:
            hint_label.text = "MASH ANY KEY!"
            struggle_bar.visible = true

func _on_struggle_updated(current_force: float, max_force: float) -> void:
    # Cập nhật thanh lực giằng co
    struggle_bar.max_value = max_force
    struggle_bar.value = current_force

func _on_game_result(player_won: bool) -> void:
    # Hiển thị text Thắng/Thua
    struggle_bar.visible = false
    if player_won:
        hint_label.text = "YOU WIN! +100 Score"
    else:
        hint_label.text = "COW ESCAPED..."
