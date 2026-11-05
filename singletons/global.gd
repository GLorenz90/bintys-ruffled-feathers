extends Node

#region CONSTANTS ==============================================================
const MAX_Y_SPEED := 100.0;
#endregion =====================================================================

#region COMPONENTS =============================================================
var main: Main;
var camera: Camera3D;              # The main (left / shared) camera. For a specific player, use get_camera_for_player().
var camera_director: CameraDirector;
var ui_layer: Control;
var p1_char: PlayerCharacter;
var p2_char: PlayerCharacter;
var device_manager: DeviceManager;
var input_manager: InputManager;
var current_level: Node3D;
#endregion =====================================================================

var _active_hit_stops := 0;

#region FUNCTIONS ==============================================================
func change_level(level_scene: PackedScene) -> void:
  main.load_level(level_scene);
#/change_level

func get_player(player_id: int) -> PlayerCharacter:
  return p1_char if player_id == 1 else p2_char;
#/get_player

func get_camera_for_player(player_id: int) -> Camera3D:
  return camera_director.get_camera_for_player(player_id) if camera_director != null else camera;
#/get_camera_for_player

# Briefly slows the whole game almost to a stop so a hit lands with weight.
# Overlapping hit stops keep it slowed until the last one ends.
func hit_stop(duration: float) -> void:
  if duration <= 0.0: return;
  _active_hit_stops += 1;
  Engine.time_scale = CharStats.HIT_STOP_TIME_SCALE;

  await get_tree().create_timer(duration, true, false, true).timeout; # Real time, even while slowed or paused.
  _active_hit_stops -= 1;
  if _active_hit_stops == 0: Engine.time_scale = 1.0;
#/hit_stop

func get_living_players() -> Array[PlayerCharacter]:
  var players: Array[PlayerCharacter] = [];
  for player in [p1_char, p2_char]:
    if player != null && player.is_alive(): players.append(player);
  #/for
  return players;
#/get_living_players

func to_fixed(value: float, digits: int) -> String:
  var big_value = round(value * 10**digits);
  var smaller_value = big_value / 10**digits;
  return str(smaller_value);
#/to_fixed
#endregion =====================================================================
