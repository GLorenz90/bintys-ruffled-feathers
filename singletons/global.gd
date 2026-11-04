extends Node

#region CONSTANTS ==============================================================
const MAX_Y_SPEED := 100.0;
#endregion =====================================================================

#region COMPONENTS =============================================================
var main: Main;
var camera: Camera3D;
var ui_layer: Control;
var p1_char: PlayerCharacter;
var p2_char: PlayerCharacter;
var device_manager: DeviceManager;
var input_manager: InputManager;
var current_scene: Node3D;
#endregion

#region FUNCTIONS ==============================================================
func to_fixed(value: float, digits: int) -> String:
  var big_value = round(value * 10**digits);
  var smaller_value = big_value / 10**digits;
  return str(smaller_value);
#/to_fixed
#endregion
