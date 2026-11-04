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

func to_fixed(value: float, digits: int) -> String:
  var big_value = round(value * 10**digits);
  var smaller_value = big_value / 10**digits;
  return str(smaller_value);
#/to_fixed
#endregion =====================================================================
