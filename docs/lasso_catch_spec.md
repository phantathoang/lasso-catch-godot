# Lasso Catch – Godot 4 Production Spec

## 0. Mục tiêu & Bối cảnh

**Mục tiêu**  
Thiết kế và triển khai game 2D **Lasso Catch** bằng **Godot Engine 4.x (GDScript)** theo chuẩn production-ready: kiến trúc rõ ràng, dễ mở rộng, dễ bảo trì, có thể đem đi polish và xuất bản.

**Bối cảnh gameplay**

- Người chơi là Cowboy đứng gần đáy màn hình, ở chính giữa.
- Bò chạy ngang qua màn hình, spawn ngẫu nhiên từ ngoài rìa.
- Người chơi quăng thòng lọng (lasso) để bắt bò.
- Khi lasso móc vào bò, vào phase **STRUGGLING**: người chơi “mash any key” để giằng co với bò.
- Kết quả (bắt được / bò trốn) dẫn đến tính điểm và vòng chơi tiếp theo.

**Yêu cầu kỹ thuật tổng quát**

- Godot 4.x, GDScript 2.x, style snake_case.
- Tổ chức project theo **domain-based folders** thay vì “Scripts/Scenes/Textures”.
- Ưu tiên **Composition over Inheritance** cho entity logic (component scripts thay vì cây class sâu).
- Sử dụng **Autoload + state machine** để điều khiển flow game.

---

## 1. Kiến trúc Dự án & Tổ chức Thư mục

### 1.1. Triết lý

- **Domain-based organization**
  - Nhóm mọi thứ theo “miền trách nhiệm” (systems, entities, ui, assets, levels, resources).
  - Mỗi entity (player, cow, lasso) tự chứa scene, script, resource liên quan trong cùng folder.
- **Composition over inheritance**
  - Dùng component script như `MovementComponent`, `StruggleComponent`, `HealthComponent` nếu cần.
  - Tránh tạo class base chung rồi kế thừa sâu cho từng kiểu bò, v.v.

### 1.2. Cấu trúc thư mục chuẩn

```text
res://
  systems/
    game_manager.gd
    input_handler.gd
    signal_bus.gd        # optional

  entities/
    player/
      player.tscn
      player.gd
      # sprites, animations, components...

    cow/
      cow.tscn
      cow.gd
      cow_data.tres      # Resource cấu hình

    lasso/
      lasso.tscn         # thân dây (Line2D, logic vẽ)
      lasso_head.tscn    # đầu dây (Area2D)
      lasso.gd
      lasso_head.gd

  ui/
    main_menu/
      main_menu.tscn
    hud/
      hud.tscn
    themes/
      default_theme.tres

  assets/
    audio/
    fonts/
    vfx/

  levels/
    level_base.tscn      # scene gameplay chính
    environment/         # background, tiles, decor

  resources/
    CowData.tres         # config bò (speed, lực kéo, điểm)
    DifficultyCurve.tres # config độ khó, spawn rate
```

- `systems/`: các hệ thống global (Autoload, input, signal bus).
- `entities/`: tất cả thực thể có logic trong game.
- `ui/`: UI và theme, style.
- `assets/`: tài nguyên raw (ảnh, âm thanh, vfx).
- `levels/`: các màn chơi (hiện chỉ cần 1 level chính).
- `resources/`: các resource config dễ chỉnh mà không đụng code.

---

## 2. GameManager & State Machine (Autoload)

### 2.1. GameManager

- File: `res://systems/game_manager.gd`.
- Đăng ký trong **Project Settings → Autoload**:
  - Name: `GameManager`
  - Path: `res://systems/game_manager.gd`
  - Singleton: on

**Nhiệm vụ chính**

- Giữ **state tổng** của game:

```gdscript
enum GameState {
    MENU,
    SPAWNING,
    CATCHING,
    STRUGGLING,
    RESULT
}

var state: GameState = GameState.MENU
```

- Hàm `set_state(new_state: GameState)`:
  - Nếu state mới khác state hiện tại:
    - Gọi `exit_state(state)` (optional).
    - Cập nhật `state`.
    - Gọi `enter_state(state)` để khởi động logic cho state mới.
  - Bên trong `enter_state` và `exit_state` sử dụng `match` cho từng trạng thái.

- Phát signal, ví dụ: `signal state_changed(old_state, new_state)` để HUD, Spawner, Player có thể subscribe nếu cần.

### 2.2. Flow trạng thái

- `MENU`:
  - Hiển thị main menu.
  - Chờ người chơi nhấn “Start” để `set_state(SPAWNING)`.

- `SPAWNING`:
  - Bật Spawner: spawn bò theo thời gian và độ khó (DifficultyCurve).
  - Player có thể ném lasso (state game cho phép bắt bò).

- `CATCHING`:
  - Trạng thái “đang săn bò”.
  - Lasso hoạt động, Cow chạy, Spawner vẫn có thể spawn thêm.
  - Có thể gộp SPAWNING + CATCHING nếu muốn đơn giản hơn.

- `STRUGGLING`:
  - Kích hoạt khi Lasso bắt trúng bò.
  - Tạm dừng spawn mới, tập trung vào giằng co.
  - Mash-any-key để người chơi “kéo” bò, bò “kéo ngược”.

- `RESULT`:
  - Hiển thị kết quả giằng co:
    - Player thắng → bò bị kéo về, cộng điểm.
    - Bò thắng → bò trốn, không cộng điểm.
  - Sau một khoảng delay ngắn:
    - Trở về `SPAWNING` để tiếp tục vòng mới, hoặc `MENU` nếu kết thúc session.

---

## 3. Tutorial: Quy trình Tạo Game Cho Người Mới

(Phần này để AI trình bày lại dạng hướng dẫn; dev mới đọc là hiểu workflow.)

### 3.1. Bước 1 – Tạo project

- Mở Godot 4.x → **New Project** → đặt tên `LassoCatch` → chọn folder → Create & Edit.
- Vào **Project Settings → Rendering → Renderer**:
  - Chọn **Compatibility** (OpenGL) cho game 2D, dễ target Web/Mobile.
- Vào **Project Settings → Display → Window → Stretch**:
  - Mode: `canvas_items`
  - Aspect: `keep`
  - Đảm bảo pixel art không méo khi đổi kích thước.

### 3.2. Bước 2 – Tạo LevelBase (scene gameplay chính)

- Tạo scene mới → root là `Node2D` → rename `LevelBase`.
- Lưu: `res://levels/level_base.tscn`.
- Hierarchy đề xuất:

```text
LevelBase (Node2D)
 ├─ Player (CharacterBody2D instanced)
 ├─ Spawner (Node2D)
 ├─ Background (Node2D/Sprite2D)
 └─ HUD (CanvasLayer instanced)
```

- Trong **Project Settings → Run → Main Scene** chọn `levels/level_base.tscn` để chạy game.

### 3.3. Bước 3 – Tạo Player + Lasso

#### Player scene

- Tạo scene mới:
  - Root: `CharacterBody2D` → rename `Player`.
  - Thêm children:

    ```text
    Player (CharacterBody2D)
     ├─ Sprite2D
     ├─ Hand (Marker2D)
     ├─ Lasso (Line2D)
     ├─ LassoHead (Area2D)
     │    └─ CollisionShape2D (CircleShape2D)
     └─ AnimationPlayer (optional)
    ```

- Lưu: `res://entities/player/player.tscn`.

#### Player script (tóm tắt hành vi)

- File: `res://entities/player/player.gd`.

Chức năng:

1. **Input ném lasso**

   - Trong `_input(event)` hoặc `_unhandled_input(event)`:
     - Nếu click chuột trái và `GameManager.state` đang cho phép (`SPAWNING`/`CATCHING`) và lasso đang sẵn sàng:
       - Tính hướng ném: `mouse_pos - hand_pos`.
       - Giới hạn khoảng cách bằng `max_distance`.
       - Dùng `create_tween()` để Tween `lasso_head.global_position` từ `hand.global_position` tới target (Ease-Out).

2. **Xử lý khi LassoHead chạm bò hoặc hết tầm**

   - Khi Tween đi tới kết thúc mà không trúng gì → gọi Tween quay về Hand (Ease-In).
   - Khi Area2D LassoHead `area_entered` Cow:
     - Tắt collision hoặc monitoring (`CollisionShape2D.disabled` qua `set_deferred`) để tránh double trigger.
     - Thông báo GameManager chuyển sang `STRUGGLING`.

3. **Cập nhật Line2D dây**

   - Trong `_process(delta)`:
     - Đảm bảo `lasso.points.size() == 2`.
     - `lasso.set_point_position(0, lasso.to_local(hand.global_position))`.
     - `lasso.set_point_position(1, lasso.to_local(lasso_head.global_position))`.

### 3.4. Bước 4 – Tạo Cow

- Tạo scene mới:
  - Root: `CharacterBody2D` (ưu tiên, dễ control movement & collision).
  - Children:

    ```text
    Cow (CharacterBody2D)
     ├─ Sprite2D
     ├─ CollisionShape2D
     └─ CPUParticles2D (optional – bụi)
    ```

- Lưu: `res://entities/cow/cow.tscn`.

Script `cow.gd` (tóm tắt):

- Khi `_ready()`:
  - Lấy config từ `CowData` (Resource).
  - Xác định hướng (trái sang phải / phải sang trái) ngẫu nhiên.
  - Đặt vị trí spawn ở ngoài rìa viewport (dùng `get_viewport_rect().size` + margin).
- Trong `_physics_process(delta)`:
  - Cập nhật `velocity` theo hướng.
  - `move_and_slide()` (nếu là CharacterBody2D).
  - Nếu ra khỏi màn hình + margin → `queue_free()`.

### 3.5. Bước 5 – Tạo Spawner

- Trong `LevelBase`, thêm node `Spawner` (Node2D).
- Gắn script `spawner.gd` (đặt ở `res://systems/spawner.gd` hoặc `res://levels/spawner.gd`).

Chức năng:

- Khi GameManager.state == `SPAWNING`:
  - Dùng Timer hoặc logic thời gian để spawn Cow định kỳ.
  - Lựa chọn cạnh spawn (trên/dưới/trái/phải).
  - Random vị trí trên cạnh đó + margin ngoài viewport.
  - Hướng bò chạy vào giữa màn hình.

---

## 4. Cơ Chế “Mash Any Key”

### 4.1. Input xử lý mọi phím

- Implement trong `input_handler.gd` (Autoload) hoặc trong `GameManager`.
- Sử dụng `_unhandled_key_input(event)` hoặc `_input(event)`.

Pseudo-code:

```gdscript
func _unhandled_key_input(event: InputEvent) -> void:
    if GameManager.state != GameManager.GameState.STRUGGLING:
        return

    if event is InputEventKey and event.is_pressed() and not event.is_echo():
        _on_valid_key_press()
```

- `_on_valid_key_press()` tăng lực người chơi mỗi lần nhấn phím.

### 4.2. Lực giằng co & HUD

Biến (ở GameManager hoặc component chuyên trách):

- `var player_force := 0.0`
- `var cow_force := 0.0`
- `var max_force := 100.0`

Logic trong `STRUGGLING`:

- Mỗi lần nhấn phím hợp lệ:
  - `player_force += player_increment` (ví dụ 2–3 mỗi lần).
- Mỗi frame:
  - `cow_force += cow_pull_rate * delta` (ví dụ 10 * delta).
- HUD:
  - `StruggleBar.value = clamp(player_force - cow_force, 0.0, max_force)`.

Kết thúc STRUGGLING:

- Nếu `player_force - cow_force >= max_force`:
  - Player thắng → bò bị kéo về phía player bằng Tween, cộng điểm.
- Nếu thời gian STRUGGLING hết hoặc `player_force - cow_force <= 0` (tuỳ thiết kế):
  - Bò thắng → bò trốn, không cộng điểm.
- Cả hai trường hợp → `set_state(RESULT)` và chuẩn bị vòng tiếp theo.

---

## 5. UI & Game Feel

### 5.1. HUD & UI Responsive

- HUD scene: `res://ui/hud/hud.tscn`.
- Root: `CanvasLayer` (layer = 1).
- Bên trong:
  - `ScoreLabel` (Label) – hiển thị điểm.
  - `StruggleBar` (ProgressBar) – hiển thị lực giằng co.
  - `HintLabel` (Label) – hiển thị hướng dẫn (“Click to throw”, “Mash any key!”).

Nguyên tắc responsive:

- Dùng `Control` node, anchors và `HBoxContainer`/`VBoxContainer` để bố trí các elements.
- Sử dụng `Theme` để quản lý font, màu sắc đồng nhất toàn game.

### 5.2. Game Feel (Polish)

Gợi ý:

- **Particles**
  - CPUParticles2D cho bụi bò chạy, impact khi lasso móc vào, hiệu ứng thắng.
- **Camera Shake**
  - Rung nhẹ camera khi lasso trúng bò hoặc khi mash-any-key mạnh.
- **Freeze Frame**
  - Dừng game ~0.05s khi lasso trúng để tạo impact.
- **Tween UI**
  - Score tăng → scale Label lên rồi tween về bình thường.
  - HUD elements fade in/out khi chuyển state STRUGGLING/RESULT.

---

## 6. Tối Ưu & Export

### 6.1. Hiệu năng

- Renderer: **Compatibility** cho 2D, tối ưu Web + Mobile.
- Dùng `VisibleOnScreenNotifier2D` hoặc check viewport để free entity ra khỏi màn hình.
- Hạn chế logic nặng trong `_process/_physics_process`; ưu tiên dùng Timer, signals, Resources.
- Với nhiều sprite, cân nhắc dùng texture atlas (AtlasTexture) để giảm draw calls.

### 6.2. Export

Trước khi export:

- Xoá `print()` / debug log không cần thiết.
- Kiểm tra **Input Map**:
  - ESC (thoát / pause), confirm, restart.
- Thiết lập:
  - Icon app.
  - Splash screen.
  - Preset export cho:
    - PC (Windows/macOS/Linux).
    - Web (HTML5) – chọn Compatibility renderer, tắt threads nếu cần.
    - Mobile (Android/iOS) – chú ý texture compression (ETC2) và kích thước build.

---

## 7. Hướng Dẫn Cho AI IDE (Antigravity)

Khi sử dụng AI IDE (Antigravity):

- Luôn cung cấp context:
  - “Spec game nằm ở `docs/lasso_catch_spec.md` – hãy đọc kỹ trước khi lập kế hoạch hoặc sửa code.”
- Chia work theo **phase**:
  1. Phase 1: tạo folder structure, LevelBase, scene & script rỗng, Autoload GameManager.
  2. Phase 2: implement core gameplay (Player + Lasso + Cow + Spawner).
  3. Phase 3: implement GameManager state machine + mash-any-key + HUD.
  4. Phase 4: polish (UI, particles, camera shake, freeze frame).
  5. Phase 5: optimization + export setup.

Spec này là **single source of truth** cho kiến trúc, gameplay, UI và quy trình kỹ thuật của Lasso Catch.
