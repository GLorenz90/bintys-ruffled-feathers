extends CanvasLayer
class_name DebugOverlay

# Press F3 to show or hide. Shows frame rate, then each player's device, state and movement.
# F4 drops Glinty (P2) in beside Binty, for testing co-op without a second controller.

const TOGGLE_KEY := KEY_F3;
const SPAWN_P2_KEY := KEY_F4;

@onready var _label: Label = $Text;

func _ready() -> void:
  visible = false;
#/_ready

func _input(event: InputEvent) -> void:
  if !(event is InputEventKey) || !event.pressed || event.echo: return;
  if event.keycode == TOGGLE_KEY: visible = !visible;
  if event.keycode == SPAWN_P2_KEY: Global.main.spawn_player_two();
#/_input

func _process(_delta: float) -> void:
  if !visible: return;

  var lines: PackedStringArray = ["FPS: %d" % Engine.get_frames_per_second()];
  if Global.camera_director != null: lines.append("Camera: %s" % Global.camera_director.get_mode_name());
  lines.append("Lives: %d  Deaths: %d  Death Counter: %s" % [GameState.lives, GameState.death_count, "on" if GameState.death_counter_mode else "off"]);
  for player_id in [1, 2]:
    lines.append("");
    lines.append_array(_player_lines(player_id));
  #/for
  _label.text = "\n".join(lines);
#/_process

func _player_lines(player_id: int) -> PackedStringArray:
  var device := Global.device_manager.get_device_label(player_id);
  var player := Global.get_player(player_id);
  if player == null: return ["P%d: not joined (%s). F4 to drop in." % [player_id, device]];

  return [
    "P%d %s (%s)" % [player_id, player.name, device],
    "  state: %s  health: %d/%d" % [player.get_state_name(), player.get_health(), player.get_max_health()],
    "  velocity: %s" % _format_vector(player.velocity),
    "  speed: %.2f" % Vector2(player.velocity.x, player.velocity.z).length(),
    "  on floor: %s" % player.is_on_floor(),
    "  air: %.1f  in water: %s" % [player.env.air, player.env.is_in_water()],
  ];
#/_player_lines

func _format_vector(value: Vector3) -> String:
  return "(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z];
#/_format_vector
